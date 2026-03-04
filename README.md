# AlarmApp MVP (iOS 17+)

## Required capabilities / plist
- `NSUserNotificationUsageDescription`: "Notifications are required to fire alarms and mission reminders."
- Background Modes -> Audio, AirPlay, and Picture in Picture (for reliable alarm loop while active).
- Optional for future steps mission: `NSMotionUsageDescription`.

## Notes
- No snooze is implemented by design.
- Emergency Stop always available in ringing flow.
- Notification ladder uses a 64-request budget cap.
