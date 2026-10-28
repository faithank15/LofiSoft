<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rentals', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('rental_unit_id')->constrained('rental_units')->cascadeOnDelete();
            $table->foreignUuid('tenant_id')->nullable()->constrained('users')->nullOnDelete();
            $table->date('date_debut');
            $table->date('date_fin')->nullable();
            $table->decimal('loyer_mensuel', 12, 2);
            $table->decimal('caution', 12, 2)->default(0);
            $table->unsignedTinyInteger('jour_echeance')->default(5);
            $table->string('periodicite')->default('MENSUEL');
            $table->string('statut')->default('ACTIVE');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rentals');
    }
};
