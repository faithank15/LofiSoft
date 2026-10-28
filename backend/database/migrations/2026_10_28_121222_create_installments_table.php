<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('installments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('rental_id')->constrained('rentals')->cascadeOnDelete();
            $table->date('date_debut');
            $table->date('date_fin');
            $table->decimal('montant_du', 12, 2);
            $table->decimal('montant_paye', 12, 2)->default(0);
            $table->boolean('est_solde')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('installments');
    }
};
