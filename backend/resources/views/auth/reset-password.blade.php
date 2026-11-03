<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Réinitialiser le mot de passe — LofiSoft</title>
    <style>
        :root {
            --ink: #10231E;
            --green: #0F5C4D;
            --cream: #F7F3EA;
            --line: #E1DACB;
            --grey: #55645E;
            --bad: #B3261E;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
            background: var(--cream);
            color: var(--ink);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            line-height: 1.5;
        }
        .card {
            width: 100%;
            max-width: 420px;
            background: #fff;
            border: 1px solid var(--line);
            border-radius: 20px;
            padding: 32px 28px;
            box-shadow: 0 12px 40px rgba(16, 35, 30, 0.16);
        }
        h1 { margin: 0 0 6px; font-size: 24px; }
        p.sub { margin: 0 0 24px; color: var(--grey); font-size: 15px; }
        label { display: block; margin-bottom: 6px; font-size: 14px; font-weight: 600; }
        input {
            width: 100%;
            padding: 12px 14px;
            margin-bottom: 18px;
            border: 1px solid var(--line);
            border-radius: 12px;
            font-size: 16px;
            background: #fff;
            color: var(--ink);
        }
        input:focus { outline: 2px solid var(--green); outline-offset: 1px; }
        button {
            width: 100%;
            padding: 14px;
            border: 0;
            border-radius: 14px;
            background: var(--green);
            color: #fff;
            font-size: 16px;
            font-weight: 700;
            cursor: pointer;
        }
        button:hover { background: #0B4A3E; }
        .alert {
            padding: 12px 14px;
            margin-bottom: 20px;
            border-radius: 12px;
            font-size: 14px;
        }
        .alert.error { background: #FDECEA; color: var(--bad); }
        .alert.success { background: #E6F4EC; color: #0B6B3A; }
        ul { margin: 0 0 20px; padding-left: 20px; color: var(--bad); font-size: 14px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Choisir un nouveau mot de passe</h1>
        <p class="sub">Votre nouveau mot de passe doit contenir au moins 8 caractères.</p>

        @if ($error)
            <div class="alert error">{{ $error }}</div>
        @endif

        @if ($success)
            <div class="alert success">{{ $success }}</div>
            <p class="sub">Vous pouvez fermer cette page et ouvrir l'application LofiSoft.</p>
        @else
            @if ($errors->any())
                <ul>
                    @foreach ($errors->all() as $message)
                        <li>{{ $message }}</li>
                    @endforeach
                </ul>
            @endif

            <form method="POST" action="{{ url('/reset-password') }}">
                @csrf
                <input type="hidden" name="token" value="{{ $token }}">

                <label for="email">Adresse e-mail</label>
                <input id="email" type="email" name="email" value="{{ old('email', $email) }}" required autocomplete="email">

                <label for="password">Nouveau mot de passe</label>
                <input id="password" type="password" name="password" required autocomplete="new-password">

                <label for="password_confirmation">Confirmer le mot de passe</label>
                <input id="password_confirmation" type="password" name="password_confirmation" required autocomplete="new-password">

                <button type="submit">Enregistrer le mot de passe</button>
            </form>
        @endif
    </div>
</body>
</html>
