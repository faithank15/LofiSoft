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
            $table->foreignUuid('owner_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('housing_id')->nullable()->constrained('housings')->nullOnDelete();
            $table->string('title');
            $table->string('type')->default('ROOM');
            $table->unsignedInteger('rent');
            $table->unsignedTinyInteger('deposit_months')->default(1);
            $table->string('city')->index();
            $table->string('district')->index();
            $table->unsignedTinyInteger('rooms')->default(1);
            $table->text('description')->nullable();
            $table->string('status')->default('DRAFT');
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('announcements');
    }
};
