<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rent_periods', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('rental_id')->constrained('rentals')->cascadeOnDelete();
            $table->string('period', 7); // Format AAAA-MM
            $table->unsignedInteger('total');
            $table->unsignedInteger('carried_over')->default(0);
            $table->date('due_date');
            $table->timestamps();

            $table->unique(['rental_id', 'period']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rent_periods');
    }
};
