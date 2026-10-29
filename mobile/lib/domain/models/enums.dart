/// Énumérations métier (alignées sur le diagramme de classes et l'API).
enum UserRole { TENANT, OWNER, ADMIN }

enum RentalStatus { PENDING, ACTIVE, FINISHED }

enum AnnouncementStatus { DRAFT, PUBLISHED, CANCELED, CLOSED }

enum AccommodationType { HOUSE, ROOM, OTHER }

enum ReportStatus { PENDING, RESOLVED, DISMISSED }


enum RentStatus { PAID, PARTIAL, LATE, UPCOMING }

enum PaymentStatus { PENDING, SUCCESS, FAILED }

enum Operator { MTN, MOOV, CASH }

enum IdentityStatus { PENDING, APPROVED, REJECTED }
