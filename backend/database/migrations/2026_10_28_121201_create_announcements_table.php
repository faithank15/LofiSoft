<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('announcements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('rental_unit_id')->nullable()->constrained('rental_units')->nullOnDelete();
            $table->string('titre');
            $table->text('description')->nullable();
            $table->decimal('loyer_mensuel', 12, 2);
            $table->string('ville')->index();
            $table->string('quartier')->index();
            $table->string('adresse');
            $table->string('point_repere');
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->string('statut')->default('PUBLISHED');
            $table->timestamp('date_publication')->useCurrent();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('announcements');
    }
};
