# Mockups — F-003: Calendar & Capacity Visualization

## Index

| Flow | Step | State | File |
|------|------|-------|------|
| team-calendar | grid | default | [team-calendar-default.html](team-calendar-default.html) |
| heat-map | grid | default | [heat-map-default.html](heat-map-default.html) |
| dashboard | overview | default | [dashboard-default.html](dashboard-default.html) |

## Assumptions

- Team calendar: rows = employees, columns = weekdays; colour bars by status
- Heat map: CSS grid; cells colour-coded by capacity band (green/yellow/orange/red)
- Drill-down panel shown below the grid when a critical cell is clicked (inline, not modal)
- Alternative date suggestions shown in the drill-down panel (green-tinted card)
- Dashboard: 4 metric cards (on vacation, available, pending, avg approval time)
- Over-capacity alerts are cards with "View Heat Map" CTA for next 90 days
- Org level selector (Department / Project / Team) shown on heat-map view
- Weekly/monthly toggle on team calendar

## States Omitted

| State | Justification |
|-------|---------------|
| empty | Calendar empty state is a clear week grid with no bars; self-explanatory |
| error | Calendar data from pre-computed snapshots + Redis; errors are rare API failures |
| loading | Render target is < 1s from cache; skeleton not critical for lo-fi |
