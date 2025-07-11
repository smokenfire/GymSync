# BackendService for GymSync

> [!TIP]  
> The `_baseUrl` is already set to use a public backend provided by TheusHen to simplify builds and development.  
>  
> You are free to replace it with your own backend URL if you prefer.

## About `_baseUrl`

In the file `BackendService.dart`, the constant `_baseUrl` points to a public backend API:

```dart
static const String _baseUrl = 'https://gymsync-backend-orcin.vercel.app/api/v1/status';
```
