# Today Salary - Daily Income Tracker

A modern iOS app for tracking daily earnings with real-time progress tracking and gamification features, specifically designed for US users.

## 🌟 Features

### Core Functionality
- **Smart Income Calculation**: Input monthly income and the app calculates daily targets based on actual month days (28-31 days) or working days (Mon-Fri only)
- **Real-time Progress Tracking**: Visual progress bar showing how close you are to your daily goal
- **Time-based Auto-calculation**: Automatically calculates earnings based on your work hours and current time
- **Multiple Calculation Methods**: Choose between natural days (all days) or working days (weekdays only)

### New Time-based Features ⏰
- **Automatic Earnings Update**: App automatically calculates your current earnings based on time worked
- **Work Hours Configuration**: Set your daily work schedule (start time, end time)
- **Working Status Display**: Shows if you're currently in work hours and tracks hours worked today
- **Hourly Rate Display**: Shows your hourly earning rate
- **Real-time Sync**: Income updates every minute during work hours

### Work Schedule Settings 🕘
- **Daily Work Hours**: Configure start and end times for your work day
- **Auto-calculate Toggle**: Enable/disable automatic time-based income calculation
- **Working Day Detection**: Automatically detects weekends when using working days mode
- **Hourly Progress**: Visual progress bar showing hours worked vs total work hours

### Payday Features 💰
- **Payday Configuration**: Set your payday (specific date or last day of month)
- **Payday Countdown**: See how many days until your next payday
- **Monthly Cycle Tracking**: Automatically resets calculations for new months

### Smart Notifications
- **Goal Achievement Alerts**: Get notified when you reach your daily target
- **Achievement Unlocks**: Notifications for unlocking new achievements
- **Challenge Completions**: Alerts when you complete daily challenges
- **Daily Reminders**: Optional evening reminders to track your progress

### Gamification System
- **6 Achievement Badges**: 
  - First Dollar (earn your first dollar)
  - Half Way There (reach 50% of daily goal)
  - Goal Crusher (reach 100% of daily goal)
  - Overachiever (exceed daily goal by 50%)
  - Weekly Warrior (meet daily goal 7 days in a row)
  - Coffee Money (earn enough for a Starbucks!)

- **Daily Challenges**: Fun, US-localized challenges like:
  - Coffee Run ($5 - earn enough for morning coffee)
  - Lunch Money ($15 - earn enough for a nice lunch)
  - Movie Night ($12 - earn enough for a movie ticket)
  - Quick Start (30% of daily goal)

### Intelligent Progress Analysis
- **Month Overview**: See total days, working days, and remaining days in current month
- **Advanced Statistics**: Track remaining target, average needed per remaining day
- **Performance Alerts**: Get warned if you're falling behind your monthly goal
- **Dynamic Recalculation**: Automatically adjusts when month changes

### Modern UI/UX
- **SwiftUI Interface**: Clean, modern design with smooth animations
- **Responsive Design**: Adapts to different screen sizes
- **Dark/Light Mode**: Supports system appearance settings
- **Keyboard Management**: Smart keyboard handling with toolbar controls
- **Progress Visualizations**: Color-coded progress indicators and gradients

## 🛠 Technical Features

- **Completely Offline**: No internet required, all data stored locally
- **Core Data Ready**: Structured for easy migration to Core Data if needed
- **UserDefaults Storage**: Lightweight local data persistence
- **Real-time Updates**: ObservableObject pattern for reactive UI updates
- **Smart Date Calculations**: Accurate month-based calculations accounting for varying month lengths
- **Automatic Month Detection**: Seamlessly handles month transitions
- **Background Processing**: Timer-based automatic updates during work hours

## 📱 App Structure

### Views
- **WelcomeView**: Initial setup for new users (name, monthly income, calculation method)
- **MainView**: Main dashboard with earnings input, progress tracking, and work status
- **SettingsView**: Configuration for income, calculation method, work hours, and payday
- **AchievementsView**: Display unlocked and locked achievements

### Data Models
- **UserProfile**: Stores user configuration, work hours, and payday settings
- **DailyEarnings**: Tracks daily earning records
- **Achievement**: Achievement system data
- **Challenge**: Daily challenge system
- **WorkingHours**: Work schedule configuration with time-based calculations
- **PaydaySettings**: Payday configuration and countdown calculations

### Core Systems
- **DataManager**: Central data management with automatic updates
- **DateCalculator**: Utility for accurate date and working day calculations
- **MotivationalMessage**: Context-aware motivational messaging system
- **Notification System**: Local notifications for achievements and reminders

## 🚀 Getting Started

1. Clone the repository
2. Open `today_salary.xcodeproj` in Xcode
3. Build and run on iOS Simulator or device (iOS 15.0+)
4. Complete the welcome setup:
   - Enter your name
   - Set monthly income
   - Choose calculation method (natural days vs working days)
   - Configure work hours and payday (optional)
5. Enable automatic income calculation in settings if desired
6. Start tracking your daily earnings!

## 💡 How Automatic Calculation Works

When you enable auto-calculation in settings:

1. **Set Work Hours**: Configure your daily start and end times
2. **Automatic Tracking**: App calculates hours worked based on current time
3. **Real-time Updates**: Income updates every minute during work hours
4. **Smart Logic**: Only counts working days if you're using "Working Days" calculation method
5. **Manual Override**: You can still manually adjust earnings if needed

The app calculates your hourly rate by dividing your daily target by your total work hours, then multiplies by hours worked today.

## 🎯 US-Localized Features

- **Currency**: All amounts displayed in US Dollars ($)
- **Cultural References**: Challenges reference familiar US experiences (Starbucks, movie tickets, etc.)
- **Work Schedule**: Default 9 AM - 5 PM work hours
- **Date Formats**: US-standard date and time formatting
- **Motivational Content**: Messages tailored for US professional culture

## 🔧 Configuration Options

### Calculation Methods
- **Natural Days**: Monthly income ÷ total days in month
- **Working Days**: Monthly income ÷ working days in month (Mon-Fri)

### Work Hours Settings
- **Start/End Times**: Customizable work schedule
- **Auto-calculation**: Toggle automatic time-based income calculation
- **Hourly Rates**: Automatically calculated based on daily target and work hours

### Payday Settings
- **Monthly Date**: Set specific day of month (1-31)
- **Month End**: Option for last day of month payday
- **Countdown Display**: Shows days until next payday

## 📊 Progress Tracking

The app provides multiple levels of progress insight:

1. **Today's Progress**: Percentage of daily goal achieved
2. **Time Progress**: Hours worked vs total work hours (when auto-calc enabled)
3. **Monthly Overview**: Remaining days and required average earnings
4. **Payday Countdown**: Days until next payday
5. **Achievement Progress**: Visual badges and completion status

## 🏆 Achievement System

Unlock achievements by reaching various milestones:
- **Participation**: Just start earning
- **Progress**: Reach percentage milestones
- **Consistency**: Meet goals multiple days
- **Overachievement**: Exceed your targets
- **Cultural Milestones**: Earn enough for common purchases

## 🔄 Data Persistence

- **Local Storage**: UserDefaults for lightweight data persistence
- **Daily Records**: Each day's earnings stored separately
- **Month Transitions**: Automatic cleanup and recalculation
- **Settings Sync**: All preferences saved locally
- **Offline Operation**: No cloud dependency

## 🚀 Future Enhancements

Potential features for future versions:
- **Weekly/Monthly Charts**: Visual earning trends
- **Goal Adjustment**: Dynamic daily target modification
- **Multiple Income Streams**: Track different earning sources
- **Export Features**: Share or backup earning data
- **Widget Support**: Today View widget for quick access
- **Apple Watch**: Companion app for wrist-based tracking

## 📋 Requirements

- iOS 15.0+
- Xcode 13.0+
- SwiftUI
- UserNotifications framework

## 🎨 Design Philosophy

The app follows these design principles:
- **Simplicity**: One primary action per screen
- **Motivation**: Positive, encouraging user experience
- **Privacy**: No data collection or external dependencies
- **Performance**: Lightweight and responsive
- **Accessibility**: Support for system accessibility features

## 📝 Version History

### v2.0 (Current)
- ✨ Added time-based automatic income calculation
- ⏰ Work hours configuration and tracking
- 💰 Payday settings and countdown
- 📊 Enhanced progress analysis with working time display
- 🔄 Real-time income updates during work hours
- 🎯 Improved accuracy with working day detection

### v1.0
- ✅ Basic daily income tracking
- 📈 Progress visualization
- 🏆 Achievement system
- 🎯 Daily challenges
- 🎨 Modern SwiftUI interface
- 📱 Complete offline functionality 