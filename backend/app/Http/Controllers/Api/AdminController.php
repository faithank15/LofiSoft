<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Announcement;
use App\Models\IdentityRequest;
use App\Models\Report;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminController extends Controller
{
    public function identityRequests(Request $request): JsonResponse
    {
        $status = $request->query('status', 'PENDING');
        $requests = IdentityRequest::with('owner')->where('status', $status)->latest()->get();
        $housingsCounts = \App\Models\Housing::whereIn('owner_id', $requests->pluck('owner_id'))
            ->selectRaw('owner_id, count(*) as total')
            ->groupBy('owner_id')
            ->pluck('total', 'owner_id');

        $data = $requests->map(function ($req) use ($housingsCounts) {
            return [
                'id' => (string) $req->id,
                'owner' => [
                    'id' => (string) $req->owner_id,
                    'name' => trim(($req->owner?->prenoms ?? '') . ' ' . ($req->owner?->nom ?? '')),
                    'housings_count' => (int) ($housingsCounts[$req->owner_id] ?? 0),
                ],
                'id_image_url' => $req->id_image_url,
                'selfie_url' => $req->selfie_url,
                'status' => $req->status->value,
                'created_at' => $req->created_at->toISOString(),
            ];
        });

        return response()->json($data);
    }

    public function approveIdentity(Request $request, IdentityRequest $identityRequest): JsonResponse
    {
        if ($identityRequest->status->value !== 'PENDING') {
            return response()->json(['message' => 'Cette demande a déjà été traitée.'], Response::HTTP_CONFLICT);
        }

        $identityRequest->update([
            'status' => 'APPROVED',
            'reviewed_by' => $request->user()->id,
        ]);

        $identityRequest->owner()->update(['identity_verified' => true]);

        return response()->json(['message' => 'Propriétaire certifié avec succès.']);
    }

    public function rejectIdentity(Request $request, IdentityRequest $identityRequest): JsonResponse
    {
        $validated = $request->validate([
            'reason' => ['required', 'string'],
        ]);

        if ($identityRequest->status->value !== 'PENDING') {
            return response()->json(['message' => 'Cette demande a déjà été traitée.'], Response::HTTP_CONFLICT);
        }

        $identityRequest->update([
            'status' => 'REJECTED',
            'reason' => $validated['reason'],
            'reviewed_by' => $request->user()->id,
        ]);

        return response()->json(['message' => 'Demande rejetée.']);
    }

    public function reports(Request $request): JsonResponse
    {
        $status = $request->query('status', 'PENDING');
        $reports = Report::with('announcement.owner')->where('status', $status)->latest()->get();

        $data = $reports->map(function ($rep) {
            $reportsCount = Report::where('announcement_id', $rep->announcement_id)->count();

            return [
                'id' => (string) $rep->id,
                'reason' => $rep->reason,
                'details' => $rep->details,
                'status' => $rep->status->value,
                'created_at' => $rep->created_at->toISOString(),
                'announcement' => [
                    'id' => (string) $rep->announcement_id,
                    'title' => $rep->announcement?->title ?? 'Annonce supprimée',
                    'city' => $rep->announcement?->city,
                    'owner_name' => $rep->announcement?->owner
                        ? trim(($rep->announcement->owner->prenoms ?? '') . ' ' . ($rep->announcement->owner->nom ?? ''))
                        : null,
                ],
                'reports_count' => $reportsCount,
            ];
        });

        return response()->json($data);
    }

    public function resolveReport(Request $request, Report $report): JsonResponse
    {
        $validated = $request->validate([
            'action' => ['required', 'string', 'in:REMOVE_ANNOUNCEMENT,WARN_OWNER'],
        ]);

        if ($validated['action'] === 'REMOVE_ANNOUNCEMENT' && $report->announcement) {
            $report->announcement->update(['status' => 'CANCELED']);
        }

        $report->update(['status' => 'RESOLVED']);

        return response()->json(['message' => 'Signalement résolu.']);
    }

    public function dismissReport(Request $request, Report $report): JsonResponse
    {
        $report->update(['status' => 'DISMISSED']);

        return response()->json(['message' => 'Signalement ignoré.']);
    }

    public function users(Request $request): JsonResponse
    {
        $query = User::query();

        if ($request->filled('role')) {
            $query->where('role', $request->query('role'));
        }

        if ($request->filled('q')) {
            $q = $request->query('q');
            $query->where(function ($sub) use ($q) {
                $sub->where('nom', 'like', "%{$q}%")
                    ->orWhere('prenoms', 'like', "%{$q}%")
                    ->orWhere('email', 'like', "%{$q}%");
            });
        }

        $perPage = max(1, min(50, (int) $request->query('per_page', 20)));
        $paginator = $query->latest()->paginate($perPage);

        // Même enveloppe que les autres listes : { data: [...], meta: {...} }.
        return response()->json([
            'data' => UserResource::collection($paginator->items()),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'total' => $paginator->total(),
            ],
        ]);
    }

    public function toggleUserActive(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'actif' => ['required', 'boolean'],
        ]);

        if ($user->is($request->user()) && ! $validated['actif']) {
            return response()->json([
                'message' => 'Vous ne pouvez pas suspendre votre propre compte.',
                'errors' => ['actif' => ['Action impossible sur votre propre compte.']],
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $user->update(['actif' => $validated['actif']]);

        return response()->json(['message' => 'Statut du compte mis à jour.']);
    }
}
