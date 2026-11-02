<?php

namespace Database\Seeders;

use App\Models\Announcement;
use App\Models\Housing;
use App\Models\IdentityRequest;
use App\Models\Payment;
use App\Models\Rental;
use App\Models\RentPeriod;
use App\Models\Report;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Données de démonstration. Mot de passe de tous les comptes : Test1234.
 *
 * Comptes (les trois premiers sont ceux du FakeAuthService du mobile) :
 *   locataire@lofi.bj   TENANT  location ACTIVE, loyer du mois payé en partie
 *   proprio@lofi.bj     OWNER   vérifié, 3 logements
 *   admin@lofi.bj       ADMIN
 *   locataire2@lofi.bj  TENANT  sans location : pour tester « Rejoindre mon logement »
 *   proprio2@lofi.bj    OWNER   non vérifié, demande d'identité en attente
 *
 * Codes logement : M4T-83P (loué), K7F-29X (libre), P9Q-55D (libre).
 */
class DatabaseSeeder extends Seeder
{
    private const PASSWORD = 'Test1234';

    public function run(): void
    {
        $tenant = $this->user('Agossa', 'Patrick', 'locataire@lofi.bj', '0197123456', 'TENANT');
        $tenant2 = $this->user('Hounkpatin', 'Rose', 'locataire2@lofi.bj', '0197123457', 'TENANT');
        $owner = $this->user('Mensah', 'Koffi', 'proprio@lofi.bj', '0197000001', 'OWNER', true);
        $owner2 = $this->user('Bio-Tchané', 'Éric', 'proprio2@lofi.bj', '0197000002', 'OWNER');
        $this->user('Sanni', 'Awa', 'admin@lofi.bj', '0197000003', 'ADMIN');

        // ---- Logements et location --------------------------------------------------
        $flat = Housing::create([
            'owner_id' => $owner->id, 'title' => 'Appartement 1A', 'type' => 'HOUSE',
            'rent' => 150000, 'due_day' => 5, 'city' => 'Cotonou', 'district' => 'Fidjrossè',
            'code' => 'M4T-83P',
        ]);
        Housing::create([
            'owner_id' => $owner->id, 'title' => 'Villa Haie Vive', 'type' => 'HOUSE',
            'rent' => 280000, 'due_day' => 1, 'city' => 'Cotonou', 'district' => 'Haie Vive',
            'code' => 'K7F-29X',
        ]);
        Housing::create([
            'owner_id' => $owner2->id, 'title' => 'Studio 2B', 'type' => 'ROOM',
            'rent' => 80000, 'due_day' => 10, 'city' => 'Cotonou', 'district' => 'Akpakpa',
            'code' => 'P9Q-55D',
        ]);

        $rental = Rental::create([
            'housing_id' => $flat->id, 'tenant_id' => $tenant->id,
            'status' => 'ACTIVE', 'started_at' => now()->subMonths(3)->startOfMonth()->toDateString(),
        ]);

        // Mois précédent : payé en entier. Mois courant : 90 000 sur 150 000 (partiel).
        $previous = now()->subMonth()->format('Y-m');
        $current = now()->format('Y-m');
        RentPeriod::create([
            'rental_id' => $rental->id, 'period' => $previous, 'total' => 150000, 'carried_over' => 0,
            'due_date' => now()->subMonth()->format('Y-m').'-05',
        ]);
        RentPeriod::create([
            'rental_id' => $rental->id, 'period' => $current, 'total' => 150000, 'carried_over' => 0,
            'due_date' => $current.'-05',
        ]);
        $this->payment($rental, $previous, 150000, 'MTN', 'RC-SEED-001', now()->subMonth()->day(3));
        $this->payment($rental, $current, 90000, 'MOOV', 'RC-SEED-002', now()->day(2)->min(now()));

        // ---- Annonces ---------------------------------------------------------------
        $listings = [
            [$owner, 'Appartement · 3 pièces', 'HOUSE', 250000, 2, 'Cotonou', 'Fidjrossè', 3, 'PUBLISHED', "Appartement lumineux au 2e étage d'un immeuble sécurisé.", $flat->id],
            [$owner2, 'Maison · 4 pièces', 'HOUSE', 280000, 2, 'Cotonou', 'Haie Vive', 4, 'PUBLISHED', 'Maison avec cour fermée et deux places de parking.', null],
            [$owner, 'Appartement · 3 pièces · 85 m²', 'HOUSE', 350000, 3, 'Cotonou', 'Fidjrossè', 3, 'PUBLISHED', 'Salon, deux chambres, cuisine équipée et balcon, à 400 m de la plage.', null],
            [$owner2, 'Studio · 1 pièce', 'ROOM', 80000, 1, 'Cotonou', 'Akpakpa', 1, 'PUBLISHED', 'Studio meublé, eau et électricité à compteur personnel.', null],
            [$owner, 'Maison · 4 pièces', 'HOUSE', 250000, 2, 'Abomey-Calavi', 'Togoudo', 4, 'PUBLISHED', 'Maison récente dans un quartier calme.', null],
            [$owner, 'Chambre salon · brouillon', 'ROOM', 60000, 1, 'Porto-Novo', 'Hogbonou', 2, 'DRAFT', 'Annonce non publiée.', null],
        ];
        $created = [];
        foreach ($listings as $i => [$by, $title, $type, $rent, $deposit, $city, $district, $rooms, $status, $description, $housingId]) {
            $created[] = Announcement::create([
                'owner_id' => $by->id, 'housing_id' => $housingId, 'title' => $title, 'type' => $type,
                'rent' => $rent, 'deposit_months' => $deposit, 'city' => $city, 'district' => $district,
                'rooms' => $rooms, 'description' => $description, 'status' => $status,
                'published_at' => $status === 'PUBLISHED' ? now()->subDays($i + 1) : null,
            ]);
        }

        $tenant->favorites()->attach([$created[2]->id, $created[3]->id]);

        // ---- Modération -------------------------------------------------------------
        Report::create([
            'announcement_id' => $created[1]->id, 'reporter_id' => $tenant2->id,
            'reason' => 'Informations trompeuses', 'details' => "Le loyer affiché n'est pas le bon.",
            'status' => 'PENDING',
        ]);
        IdentityRequest::create([
            'owner_id' => $owner2->id,
            'id_image_url' => 'https://example.com/seed/identity_id.jpg',
            'selfie_url' => 'https://example.com/seed/identity_selfie.jpg',
            'status' => 'PENDING',
        ]);
    }

    private function user(string $nom, string $prenoms, string $email, string $phone, string $role, bool $verified = false): User
    {
        return User::create([
            'nom' => $nom, 'prenoms' => $prenoms, 'email' => $email, 'telephone' => $phone,
            'password' => self::PASSWORD, 'role' => $role, 'actif' => true, 'identity_verified' => $verified,
        ]);
    }

    private function payment(Rental $rental, string $period, int $amount, string $operator, string $reference, $paidAt): void
    {
        Payment::create([
            'rental_id' => $rental->id, 'period' => $period, 'amount' => $amount, 'operator' => $operator,
            'phone' => '0197123456', 'status' => 'SUCCESS', 'reference' => $reference, 'paid_at' => $paidAt,
        ]);
    }
}
