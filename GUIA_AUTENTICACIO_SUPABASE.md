# Guia d'Autenticació amb Supabase

Un cop connectada la base de dades, el següent pas és entendre com funciona l'autenticació a la teva app Flutter.

## 💡 Conceptes clau

- **Autenticació (AuthN):** verifica qui és l'usuari (ex: "Sóc en Joan").
- **Autorització (AuthZ):** verifica què pot fer l'usuari (ex: "En Joan pot llegir, però no esborrar").
- **Estat de sessió:** Supabase manté una sessió local al dispositiu perquè no calgui iniciar sessió cada cop.

Les credencials de Supabase ja estan configurades a:

- `lib/CORE/SERVICES/supabase_service.dart`

---

## 1) Pantalla de Login

Fitxer:

- `lib/CORE/LOGIN/login_screen.dart`

Punts principals:

- Captura de dades amb `_emailController` i `_passwordController`.
- Login amb `signInWithPassword`.

Exemple real del projecte:

```dart
await Supabase.instance.client.auth.signInWithPassword(
  email: _emailController.text.trim(),
  password: _passwordController.text.trim(),
);
```

Si les credencials són correctes, Supabase crea/recupera una sessió i retorna l'usuari autenticat.

---

## 2) Pantalla de Registre

Fitxer:

- `lib/CORE/LOGIN/register_screen.dart`

Punts principals:

- Validació de contrasenya i confirmació.
- Registre amb `auth.signUp(...)` (crea usuari a `auth.users`).

Exemple real del projecte:

```dart
final response = await Supabase.instance.client.auth.signUp(
  email: _emailController.text.trim(),
  password: _passwordController.text.trim(),
);
```

Flux de treball:

1. L'usuari omple el formulari.
2. Es crida `signUp`.
3. Segons la configuració del projecte Supabase, pot ser necessària confirmació per correu.

---

## 3) Tancar sessió (Logout)

Actualment, al router hi ha un botó que torna a `/`, però **no fa `signOut()` de Supabase**.

Fitxer on es veu el botó actual:

- `lib/FEATURES/router.dart`

Per fer logout real amb Supabase, fes servir:

```dart
await Supabase.instance.client.auth.signOut();
```

I després redirigeix a login:

```dart
if (context.mounted) context.go('/');
```

---

## 🚨 Incidència actual a revisar

Als fitxers de login/registre es fa `context.go('/dashboard')`, però al router actual **no existeix** la ruta `/dashboard`.

Això pot provocar errors de navegació després d'autenticar-se. Opcions ràpides:

- Canviar `/dashboard` per una ruta existent (ex: `/inicio`).
- O crear la ruta `/dashboard` al router.

---

## 🚀 Resum de mètodes

| Acció | Mètode Supabase | Objectiu |
|---|---|---|
| Entrar | `signInWithPassword()` | Validar credencials existents |
| Registrar | `signUp()` | Crear un nou compte |
| Sortir | `signOut()` | Eliminar la sessió actual |

---

## Recomanació pràctica

Per controlar autenticació de forma robusta, fes que el router decideixi pantalla segons:

- `Supabase.instance.client.auth.currentUser != null` → zona privada
- `currentUser == null` → login

Així evitaràs navegació manual inconsistent i errors de rutes.