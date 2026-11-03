<?php

namespace App\Notifications;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Rappel de loyer envoyé au locataire par le propriétaire.
 *
 * Le propriétaire déclenche l'action depuis son tableau de bord : le message
 * part réellement, et ne se contente pas de dire qu'il est parti.
 */
class RentReminderNotification extends Notification
{
    public function __construct(
        private readonly string $housingTitle,
        private readonly int $due,
        private readonly int $remaining,
        private readonly string $dueDate,
        private readonly string $ownerName,
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $message = (new MailMessage)
            ->subject('Rappel de loyer — '.$this->housingTitle)
            ->greeting('Bonjour,')
            ->line($this->ownerName.' vous rappelle le paiement du loyer de '.$this->housingTitle.'.');

        if ($this->remaining > 0) {
            $message->line('Montant restant à payer : '.$this->remaining.' FCFA (dû : '.$this->due.' FCFA).');
        } else {
            $message->line('Votre loyer est à jour. Merci.');
        }

        return $message
            ->line('Date d\'échéance : '.$this->dueDate.'.')
            ->line('Vous pouvez payer depuis l\'application LofiSoft, dans « Mon loyer ».');
    }
}
