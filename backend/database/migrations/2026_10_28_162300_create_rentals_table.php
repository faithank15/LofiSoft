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
            $table->foreignUuid('housing_id')->constrained('housings')->cascadeOnDelete();
            $table->foreignUuid('tenant_id')->constrained('users')->cascadeOnDelete();
            $table->string('status')->default('PENDING');
            $table->date('started_at');
            $table->date('ended_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rentals');
    }
};
