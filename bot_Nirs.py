import os
import json
import logging
import requests
from datetime import datetime
from dotenv import load_dotenv
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes
from telegram.request import HTTPXRequest

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s',
    level=logging.INFO
)

logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')
TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')

if not TELEGRAM_BOT_TOKEN:
    raise ValueError("No TELEGRAM_BOT_TOKEN found in environment variables")

# Supabase REST API headers
headers = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

# Dictionary for translating days of the week
WEEKDAYS = {
    'monday': 'Понедельник',
    'tuesday': 'Вторник',
    'wednesday': 'Среда',
    'thursday': 'Четверг',
    'friday': 'Пятница',
    'saturday': 'Суббота',
    'sunday': 'Воскресенье'
}

# Dictionary for weekday numbers (0 = Monday, 6 = Sunday)
WEEKDAY_NUMBERS = {
    0: 'Понедельник',
    1: 'Вторник',
    2: 'Среда',
    3: 'Четверг',
    4: 'Пятница',
    5: 'Суббота',
    6: 'Воскресенье'
}

# Reverse mapping for weekdays (Russian to English)
WEEKDAYS_REVERSE = {v: k for k, v in WEEKDAYS.items()}


def fetch_advisors(search_query=None):
    """Fetch advisors from Supabase using REST API."""
    try:
        url = f"{SUPABASE_URL}/rest/v1/scientific_advisors"

        # Add search query if provided - search by both last_name and research_field
        if search_query:
            url += f"?or=(last_name.ilike.*{search_query}*,research_field.ilike.*{search_query}*)"

        logger.info(f"Fetching advisors from URL: {url}")
        logger.info(f"Using SUPABASE_URL: {SUPABASE_URL}")
        logger.info(f"Using SUPABASE_KEY: {'set' if SUPABASE_KEY else 'not set'}")
        logger.info(f"Using headers: {headers}")

        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()

        advisors = response.json()
        logger.info(f"Received {len(advisors)} advisors from database")
        return advisors
    except requests.exceptions.Timeout:
        logger.error("Timeout while fetching advisors from Supabase")
        return None
    except Exception as e:
        logger.error(f"Error fetching advisors: {str(e)}", exc_info=True)
        return None


def get_unique_research_fields():
    """Get list of unique research fields from advisors."""
    try:
        advisors = fetch_advisors()
        if advisors:
            fields = set(advisor['research_field'] for advisor in advisors)
            return sorted(list(fields))
        return []
    except Exception as e:
        logger.error(f"Error getting research fields: {str(e)}", exc_info=True)
        return []


def format_date(date_str):
    """Convert date string from '2025-04-01' to '1 апреля 2025'"""
    date_obj = datetime.strptime(date_str, '%Y-%m-%d')
    months = {
        1: 'января', 2: 'февраля', 3: 'марта', 4: 'апреля',
        5: 'мая', 6: 'июня', 7: 'июля', 8: 'августа',
        9: 'сентября', 10: 'октября', 11: 'ноября', 12: 'декабря'
    }
    return f"{date_obj.day} {months[date_obj.month]} {date_obj.year}"


def get_weekday(date_str):
    """Get weekday name for a given date."""
    date_obj = datetime.strptime(date_str, '%Y-%m-%d')
    return WEEKDAY_NUMBERS[date_obj.weekday()]


def get_consultation_days(office_hours):
    """Get list of weekdays when advisor has consultations."""
    consultation_days = []
    for day, _ in office_hours.items():
        day_ru = WEEKDAYS.get(day.lower(), day)
        consultation_days.append(day_ru)
    return consultation_days


def filter_available_days(days, year, month, consultation_days):
    """Filter available days to only include advisor's consultation days."""
    filtered_days = []
    for day in days:
        date_str = f"{year}-{month:02d}-{day:02d}"
        weekday = get_weekday(date_str)
        if weekday in consultation_days:
            filtered_days.append(day)
    return filtered_days


def format_calendar(calendar_data, advisor):
    """Format calendar data for display."""
    if not calendar_data:
        return "Календарь не доступен"

    current_month = datetime.now().strftime("%Y-%m")
    month_data = calendar_data.get(current_month, {})

    if not month_data:
        return "Нет данных о расписании на текущий месяц"

    # Parse year and month from current_month
    year, month = map(int, current_month.split('-'))

    # Get advisor's consultation days
    consultation_days = get_consultation_days(advisor['office_hours'])

    available_days = month_data.get('available_days', [])
    # Filter available days to only include advisor's consultation days
    filtered_days = filter_available_days(available_days, year, month, consultation_days)

    busy_slots = month_data.get('busy_slots', {})

    # Get month name in Russian
    months = {
        1: 'Январь', 2: 'Февраль', 3: 'Март', 4: 'Апрель',
        5: 'Май', 6: 'Июнь', 7: 'Июль', 8: 'Август',
        9: 'Сентябрь', 10: 'Октябрь', 11: 'Ноябрь', 12: 'Декабрь'
    }
    month_name = months[month]

    result = f"📅 Расписание на {month_name} {year}:\n\n"
    result += "Доступные дни: " + ", ".join(str(day) for day in sorted(filtered_days)) + "\n\n"
    result += "Занятые слоты:\n"

    # Filter and sort busy slots
    filtered_busy_slots = {}
    for date, slots in busy_slots.items():
        weekday = get_weekday(date)
        if weekday in consultation_days:
            filtered_busy_slots[date] = slots

    # Sort dates and format them
    for date in sorted(filtered_busy_slots.keys()):
        slots = filtered_busy_slots[date]
        formatted_date = format_date(date)
        result += f"{formatted_date}: {', '.join(slots)}\n"

    return result


def format_advisor_basic_info(advisor):
    """Format basic advisor information into a message."""
    message = f"👤 *{advisor['last_name']}*\n"
    message += f"📚 Направление: {advisor['research_field']}\n"
    message += f"📧 Email: {advisor['email']}\n"
    message += f"📞 Телефон: {advisor['phone']}\n"
    message += f"👥 Лимиты студентов:\n"
    message += f"   - Бакалавриат: {advisor['bachelors_limit']}\n"
    message += f"   - Магистратура: {advisor['masters_limit']}\n"
    message += f"   - Аспирантура: {advisor['phd_limit']}\n"
    message += "🕒 Часы консультаций:\n"
    for day, hours in advisor['office_hours'].items():
        # Translate day name to Russian
        day_ru = WEEKDAYS.get(day.lower(), day)
        message += f"   - {day_ru}: {hours}\n"
    return message


def format_advisor_schedule(advisor):
    """Format advisor schedule information."""
    message = f"📅 Расписание научного руководителя *{advisor['last_name']}*:\n\n"
    message += format_calendar(advisor.get('calendar', {}), advisor)
    return message


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Send a message when the command /start is issued."""
    logger.info(f"Start command received from user {update.effective_user.id}")
    keyboard = [
        [InlineKeyboardButton("📚 Список направлений исследований", callback_data='list_advisors')],
        [InlineKeyboardButton("🔍 Поиск по фамилии или направлению", callback_data='search_field')],
        [InlineKeyboardButton("ℹ️ Помощь", callback_data='help')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.message.reply_text(
        'Добро пожаловать в бота для поиска научных руководителей!\n'
        'Выберите действие:',
        reply_markup=reply_markup
    )


async def list_advisors(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show list of research fields when list_advisors is selected."""
    logger.info("Showing research fields list")
    fields = get_unique_research_fields()

    if not fields:
        await update.callback_query.answer()
        await update.callback_query.message.reply_text(
            "К сожалению, не удалось получить список направлений исследований."
        )
        return

    keyboard = []
    for i, field in enumerate(fields):
        # Use index as callback_data to keep it short
        keyboard.append([InlineKeyboardButton(
            f"📚 {field}",
            callback_data=f'f_{i}'
        )])
        # Store the field name in context for later use
        if 'fields' not in context.user_data:
            context.user_data['fields'] = {}
        context.user_data['fields'][str(i)] = field

    # Add back button
    keyboard.append([InlineKeyboardButton("🔙 Назад в главное меню", callback_data='back_to_main')])

    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.callback_query.answer()
    await update.callback_query.message.reply_text(
        "Выберите направление исследований:",
        reply_markup=reply_markup
    )


async def show_advisors_by_field(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show advisors for selected research field."""
    query = update.callback_query
    field_id = query.data.split('_')[1]  # Get field index from callback_data

    if 'fields' not in context.user_data or field_id not in context.user_data['fields']:
        await query.answer()
        await query.message.reply_text("Произошла ошибка. Пожалуйста, начните сначала.")
        return

    field = context.user_data['fields'][field_id]
    advisors = fetch_advisors(field)

    if advisors is None or not advisors:
        await query.answer()
        await query.message.reply_text(
            f"Научных руководителей по направлению '{field}' не найдено."
        )
        return

    await query.answer()
    await query.message.reply_text(
        f"📋 Список научных руководителей по направлению '{field}':"
    )

    for advisor in advisors:
        keyboard = [
            [InlineKeyboardButton(
                "📅 Показать расписание",
                callback_data=f's_{advisor["id"]}'
            )],
            [InlineKeyboardButton(
                "🔙 К списку направлений",
                callback_data='list_advisors'
            )]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)

        message = format_advisor_basic_info(advisor)
        await query.message.reply_text(
            message,
            parse_mode='Markdown',
            reply_markup=reply_markup
        )


async def show_schedule(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show schedule for a specific advisor."""
    query = update.callback_query
    advisor_id = query.data.split('_')[1]  # Get advisor ID from callback_data

    advisors = fetch_advisors()
    if not advisors:
        await query.answer()
        await query.message.reply_text("Не удалось получить информацию о расписании.")
        return

    advisor = next((a for a in advisors if a['id'] == advisor_id), None)
    if not advisor:
        await query.answer()
        await query.message.reply_text("Научный руководитель не найден.")
        return

    await query.answer()
    message = format_advisor_schedule(advisor)

    # Add back button to return to the advisor's info
    keyboard = [[InlineKeyboardButton("🔙 Назад к информации", callback_data='list_advisors')]]
    reply_markup = InlineKeyboardMarkup(keyboard)

    await query.message.reply_text(
        message,
        parse_mode='Markdown',
        reply_markup=reply_markup
    )


async def search_field(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle advisor search."""
    logger.info(f"Search field request from user {update.effective_user.id}")
    await update.callback_query.answer()

    # Add back button to the search prompt
    keyboard = [[InlineKeyboardButton("🔙 Назад в главное меню", callback_data='back_to_main')]]
    reply_markup = InlineKeyboardMarkup(keyboard)

    await update.callback_query.message.reply_text(
        "Введите фамилию научного руководителя или направление исследований для поиска:",
        reply_markup=reply_markup
    )
    context.user_data['expecting_search'] = True


async def handle_search(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Process the search query."""
    if not context.user_data.get('expecting_search'):
        return

    search_query = update.message.text
    logger.info(f"Processing search query: {search_query}")

    advisors = fetch_advisors(search_query)

    if advisors is None:
        await update.message.reply_text(
            "Произошла ошибка при поиске научных руководителей."
        )
        return

    if not advisors:
        # Add back button when no results found
        keyboard = [[InlineKeyboardButton("🔙 Назад в главное меню", callback_data='back_to_main')]]
        reply_markup = InlineKeyboardMarkup(keyboard)

        await update.message.reply_text(
            f"По запросу '{search_query}' ничего не найдено.",
            reply_markup=reply_markup
        )
        return

    await update.message.reply_text(
        f"🔍 Результаты поиска:"
    )

    for advisor in advisors:
        keyboard = [
            [InlineKeyboardButton(
                "📅 Показать расписание",
                callback_data=f's_{advisor["id"]}'
            )],
            [InlineKeyboardButton(
                "🔙 Назад в главное меню",
                callback_data='back_to_main'
            )]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)

        message = format_advisor_basic_info(advisor)
        await update.message.reply_text(
            message,
            parse_mode='Markdown',
            reply_markup=reply_markup
        )

    context.user_data['expecting_search'] = False


async def back_to_main(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle returning to the main menu."""
    keyboard = [
        [InlineKeyboardButton("📚 Список направлений исследований", callback_data='list_advisors')],
        [InlineKeyboardButton("🔍 Поиск по фамилии или направлению", callback_data='search_field')],
        [InlineKeyboardButton("ℹ️ Помощь", callback_data='help')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.callback_query.answer()
    await update.callback_query.message.reply_text(
        'Главное меню:\nВыберите действие:',
        reply_markup=reply_markup
    )


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show help information."""
    logger.info(f"Help command requested by user {update.effective_user.id}")
    help_text = """
*Помощь по использованию бота*

Доступные команды:
/start - Начать работу с ботом
/help - Показать это сообщение

Возможности бота:
• Просмотр списка научных руководителей по направлениям
• Поиск руководителей по фамилии или направлению исследований
• Просмотр информации о лимитах набора студентов
• Контактные данные руководителей
• Расписание и календарь встреч

Для начала работы используйте команду /start
    """

    # Add back button to help message
    keyboard = [[InlineKeyboardButton("🔙 Назад в главное меню", callback_data='back_to_main')]]
    reply_markup = InlineKeyboardMarkup(keyboard)

    await update.callback_query.answer()
    await update.callback_query.message.reply_text(
        help_text,
        parse_mode='Markdown',
        reply_markup=reply_markup
    )


def main():
    """Start the bot."""
    logger.info("Starting the bot")
    try:
        # Create custom request object with increased timeout
        request = HTTPXRequest(
            connection_pool_size=8,
            read_timeout=30,
            write_timeout=30,
            connect_timeout=30,
        )

        # Create the Application with custom request
        application = Application.builder().token(TELEGRAM_BOT_TOKEN).request(request).build()

        # Add handlers
        application.add_handler(CommandHandler("start", start))
        application.add_handler(CommandHandler("help", help_command))
        application.add_handler(CallbackQueryHandler(list_advisors, pattern='^list_advisors$'))
        application.add_handler(CallbackQueryHandler(search_field, pattern='^search_field$'))
        application.add_handler(CallbackQueryHandler(help_command, pattern='^help$'))
        application.add_handler(CallbackQueryHandler(show_schedule, pattern='^s_.*$'))
        application.add_handler(CallbackQueryHandler(show_advisors_by_field, pattern='^f_.*$'))
        application.add_handler(CallbackQueryHandler(back_to_main, pattern='^back_to_main$'))
        application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_search))

        logger.info("Handlers registered successfully")

        # Start the bot with drop_pending_updates=True to avoid duplicate messages
        logger.info("Starting polling...")
        application.run_polling(
            allowed_updates=Update.ALL_TYPES,
            drop_pending_updates=True
        )
    except Exception as e:
        logger.error(f"Error starting bot: {str(e)}", exc_info=True)
        raise


if __name__ == '__main__':
    main()