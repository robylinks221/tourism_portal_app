# Tourism Portal API connection

The development API is discovered automatically from these addresses:

```text
http://sinters-macbook-pro.local:8000/api
http://127.0.0.1:8000/api
```

The Bonjour (`.local`) address works over Wi-Fi without a fixed numeric IP. The
loopback address is retained as a fallback when Android USB forwarding is
available. Keep Docker running and keep the Mac and Samsung on the same Wi-Fi.

```bash
flutter pub get
flutter run -d RZCY91RKGMA
```

You can override the API URL or Mac hostname without editing source code:

```bash
flutter run -d RZCY91RKGMA \
  --dart-define=API_BASE_URL=http://192.168.1.20:8000/api

flutter run -d RZCY91RKGMA \
  --dart-define=API_LAN_HOST=another-mac-name.local
```

Seeded accounts all use `Password123!`:

- `admin@tourism.test`
- `tourist@tourism.test`
- `guide@tourism.test`
- `operator@tourism.test`

This app currently connects live authentication endpoints: health, register,
login, current user, and logout. Tourism cards and dashboard figures remain
sample UI until the backend adds tours, bookings, schedules, reviews, and
earnings endpoints.
