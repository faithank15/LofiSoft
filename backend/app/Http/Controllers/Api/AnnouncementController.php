<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AnnouncementResource;
use App\Models\Announcement;
use App\Models\AnnouncementPhoto;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\Response;

class AnnouncementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Announcement::with(['photos', 'owner'])
            ->where('status', 'PUBLISHED');

        if ($request->filled('city')) {
            $query->where('city', 'like', '%' . $this->escapeLike($request->input('city')) . '%');
        }

        if ($request->filled('type')) {
            $query->where('type', $request->input('type'));
        }

        if ($request->filled('min_price')) {
            $query->where('rent', '>=', (int) $request->input('min_price'));
        }

        if ($request->filled('max_price')) {
            $query->where('rent', '<=', (int) $request->input('max_price'));
        }

        if ($request->filled('q')) {
            $q = $this->escapeLike($request->input('q'));
            $query->where(function ($sub) use ($q) {
                $sub->where('title', 'like', "%{$q}%")
                    ->orWhere('district', 'like', "%{$q}%");
            });
        }

        $perPage = max(1, min(50, (int) $request->input('per_page', 20)));
        $paginator = $query->latest('published_at')->paginate($perPage);

        return response()->json([
            'data' => AnnouncementResource::collection($paginator->items()),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'total' => $paginator->total(),
            ],
        ]);
    }

    public function show(Request $request, Announcement $announcement): JsonResponse
    {
        $isOwner = $request->user('sanctum')?->id === $announcement->owner_id;

        if ($announcement->status->value !== 'PUBLISHED' && ! $isOwner) {
            abort(404);
        }

        $announcement->load(['photos', 'owner']);

        return response()->json(new AnnouncementResource($announcement));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'housing_id' => ['nullable', 'uuid', Rule::exists('housings', 'id')->where('owner_id', $request->user()->id)],
            'title' => ['required', 'string', 'max:200'],
            'type' => ['required', 'string', 'in:HOUSE,ROOM,OTHER'],
            'rent' => ['required', 'integer', 'min:1000'],
            'deposit_months' => ['required', 'integer', 'min:0'],
            'city' => ['required', 'string', 'max:100'],
            'district' => ['required', 'string', 'max:100'],
            'rooms' => ['required', 'integer', 'min:1'],
            'description' => ['nullable', 'string'],
            'photos' => ['nullable', 'array', 'max:10'],
            'photos.*' => ['url'],
        ]);

        $announcement = Announcement::create([
            'owner_id' => $request->user()->id,
            'housing_id' => $validated['housing_id'] ?? null,
            'title' => $validated['title'],
            'type' => $validated['type'],
            'rent' => $validated['rent'],
            'deposit_months' => $validated['deposit_months'],
            'city' => $validated['city'],
            'district' => $validated['district'],
            'rooms' => $validated['rooms'],
            'description' => $validated['description'] ?? null,
            'status' => 'DRAFT',
        ]);

        if (! empty($validated['photos'])) {
            foreach ($validated['photos'] as $idx => $photoUrl) {
                AnnouncementPhoto::create([
                    'announcement_id' => $announcement->id,
                    'url' => $photoUrl,
                    'position' => $idx,
                ]);
            }
        }

        return response()->json(new AnnouncementResource($announcement->load('photos')), Response::HTTP_CREATED);
    }

    public function update(Request $request, Announcement $announcement): JsonResponse
    {
        if ($announcement->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Accès non autorisé.'], Response::HTTP_FORBIDDEN);
        }

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:200'],
            'type' => ['sometimes', 'string', 'in:HOUSE,ROOM,OTHER'],
            'rent' => ['sometimes', 'integer', 'min:1000'],
            'deposit_months' => ['sometimes', 'integer', 'min:0'],
            'city' => ['sometimes', 'string', 'max:100'],
            'district' => ['sometimes', 'string', 'max:100'],
            'rooms' => ['sometimes', 'integer', 'min:1'],
            'description' => ['nullable', 'string'],
        ]);

        $announcement->update($validated);

        return response()->json(new AnnouncementResource($announcement->load('photos')));
    }

    public function publish(Request $request, Announcement $announcement): JsonResponse
    {
        if ($announcement->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Accès non autorisé.'], Response::HTTP_FORBIDDEN);
        }

        if ($announcement->status->value === 'CANCELED') {
            return response()->json(['message' => 'Une annonce annulée ne peut pas être republiée.'], Response::HTTP_CONFLICT);
        }

        $announcement->update([
            'status' => 'PUBLISHED',
            'published_at' => now(),
        ]);

        return response()->json(['message' => 'Annonce publiée avec succès.']);
    }

    public function cancel(Request $request, Announcement $announcement): JsonResponse
    {
        if ($announcement->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Accès non autorisé.'], Response::HTTP_FORBIDDEN);
        }

        $announcement->update(['status' => 'CANCELED']);

        return response()->json(['message' => 'Annonce annulée.']);
    }

    public function myAnnouncements(Request $request): JsonResponse
    {
        $announcements = Announcement::with('photos')
            ->where('owner_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json(['data' => AnnouncementResource::collection($announcements)]);
    }

    public function myFavorites(Request $request): JsonResponse
    {
        $favorites = $request->user()->favorites()->with(['photos', 'owner'])->get();

        return response()->json(['data' => AnnouncementResource::collection($favorites)]);
    }

    public function addFavorite(Request $request, Announcement $announcement): JsonResponse
    {
        abort_unless($announcement->status->value === 'PUBLISHED', 404);

        $request->user()->favorites()->syncWithoutDetaching([$announcement->id]);

        return response()->json(['message' => 'Ajouté aux favoris.']);
    }

    public function removeFavorite(Request $request, Announcement $announcement): JsonResponse
    {
        $request->user()->favorites()->detach($announcement->id);

        return response()->json(null, Response::HTTP_NO_CONTENT);
    }

    public function report(Request $request, Announcement $announcement): JsonResponse
    {
        $validated = $request->validate([
            'reason' => ['required', 'string', 'max:200'],
            'details' => ['nullable', 'string'],
        ]);

        abort_unless($announcement->status->value === 'PUBLISHED', 404);

        if ($announcement->reports()->where('reporter_id', $request->user()->id)->exists()) {
            return response()->json(['message' => 'Vous avez déjà signalé cette annonce.'], Response::HTTP_CONFLICT);
        }

        $announcement->reports()->create([
            'reporter_id' => $request->user()->id,
            'reason' => $validated['reason'],
            'details' => $validated['details'] ?? null,
            'status' => 'PENDING',
        ]);

        return response()->json(['message' => 'Signalement envoyé.'], Response::HTTP_CREATED);
    }

    private function escapeLike(string $value): string
    {
        return addcslashes($value, '\\%_');
    }
}
