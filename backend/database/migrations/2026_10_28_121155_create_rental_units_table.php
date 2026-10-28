<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rental_units', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('property_id')->constrained('properties')->cascadeOnDelete();
            $table->string('nom');
            $table->text('description')->nullable();
            $table->string('adresse');
            $table->string('type')->default('ROOM');
            $table->decimal('loyer_mensuel', 12, 2);
            $table->string('code_logement', 16)->unique();
            $table->boolean('est_disponible')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rental_units');
    }
};
