<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\IdentityRequest;
use App\Models\Report;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminController extends Controller
{
    private function ensureAdmin(Request $request): ?JsonResponse
    {
        if ($request->user()->role->value !== 'ADMIN') {
            return response()->json(['message' => 'Accès réservé aux administrateurs.'], Response::HTTP_FORBIDDEN);
        }
        return null;
    }

    public function identityRequests(Request $request): JsonResponse
    {
        if ($err = $this->ensureAdmin($request)) return $err;

        $status = $request->query('status', 'PENDING');
        $requests = IdentityRequest::with('owner')->where('status', $status)->latest()->get();

        $data = $requests->map(function ($req) {
            return [
                'id' => (string) $req->id,
                'owner' => [
                    'id' => (string) $req->owner_id,
                    'name' => trim(($req->owner?->prenoms ?? '') . ' ' . ($req->owner?->nom ?? '')),
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
        if ($err = $this->ensureAdmin($request)) return $err;

        $identityRequest->update([
            'status' => 'APPROVED',
            'reviewed_by' => $request->user()->id,
        ]);

        $identityRequest->owner()->update(['identity_verified' => true]);

        return response()->json(['message' => 'Propriétaire certifié avec succès.']);
    }

    public function rejectIdentity(Request $request, IdentityRequest $identityRequest): JsonResponse
    {
        if ($err = $this->ensureAdmin($request)) return $err;

        $validated = $request->validate([
            'reason' => ['required', 'string'],
        ]);

        $identityRequest->update([
            'status' => 'REJECTED',
            'reason' => $validated['reason'],
            'reviewed_by' => $request->user()->id,
        ]);

        return response()->json(['message' => 'Demande rejetée.']);
    }

    public function reports(Request $request): JsonResponse
    {
        if ($err = $this->ensureAdmin($request)) return $err;

        $status = $request->query('status', 'PENDING');
        $reports = Report::with('announcement')->where('status', $status)->latest()->get();

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
                ],
                'reports_count' => $reportsCount,
            ];
        });

        return response()->json($data);
    }

    public function resolveReport(Request $request, Report $report): JsonResponse
    {
        if ($err = $this->ensureAdmin($request)) return $err;

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
        if ($err = $this->ensureAdmin($request)) return $err;

        $report->update(['status' => 'DISMISSED']);

        return response()->json(['message' => 'Signalement ignoré.']);
    }

    public function users(Request $request): JsonResponse
    {
        if ($err = $this->ensureAdmin($request)) return $err;

        $query = User::query();

        if ($request->filled('role')) {
            $query->where('role', $request->query('role'));
        }

        if ($request->filled('q')) {
            $q = $request->query('q');
            $query->where(function ($sub) use ($q) {
                $sub->where('nom', 'ilike', "%{$q}%")
                    ->orWhere('prenoms', 'ilike', "%{$q}%")
                    ->orWhere('email', 'ilike', "%{$q}%");
            });
        }

        return response()->json(['data' => $query->latest()->paginate(20)]);
    }

    public function toggleUserActive(Request $request, User $user): JsonResponse
    {
        if ($err = $this->ensureAdmin($request)) return $err;

        $validated = $request->validate([
            'actif' => ['required', 'boolean'],
        ]);

        $user->update(['actif' => $validated['actif']]);

        return response()->json(['message' => 'Statut du compte mis à jour.']);
    }
}
