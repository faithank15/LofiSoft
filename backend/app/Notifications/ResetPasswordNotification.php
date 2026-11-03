<?php

namespace App\Notifications;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Lien de réinitialisation du mot de passe.
 *
 * Le lien pointe vers la page web du backend : l'utilisateur choisit son nouveau
 * mot de passe dans son navigateur, sans avoir à installer une version récente
 * de l'application. Un App Link pourra être posé plus tard sur cette même page.
 */
class ResetPasswordNotification extends Notification
{
    public function __construct(private readonly string $token) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $url = url('/reset-password?token='.$this->token.'&email='.urlencode((string) $notifiable->email));

        return (new MailMessage)
            ->subject('Réinitialisez votre mot de passe LofiSoft')
            ->greeting('Bonjour,')
            ->line('Vous avez demandé la réinitialisation de votre mot de passe LofiSoft.')
            ->action('Choisir un nouveau mot de passe', $url)
            ->line('Ce lien est valable '.config('auth.passwords.users.expire').' minutes.')
            ->line('Si vous n\'êtes pas à l\'origine de cette demande, ignorez simplement ce message.');
    }
}
