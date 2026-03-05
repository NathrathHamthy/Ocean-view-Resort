# Ocean View Resort - Hotel Booking and Management System

Source-verified README for the current repository state.

Last verified: 2026-03-01
Package: `war` (`target/oceanview-resort.war`)
Artifact: `com.oceanview:ocean-view-resort:1.0.0`

## Overview

Ocean View Resort is a Jakarta EE web application for hotel operations with three roles:

- Admin
- Staff
- Guest

The codebase is structured with Servlets (controllers), JSP views, DAO + Service layers, and MySQL persistence.

## Stack

Backend:

- Java 11
- Jakarta Servlet 5.0.0
- Jakarta JSP 3.0.0
- JSTL 2.0.0
- JDBC + Apache Commons DBCP2 (connection pooling)
- MySQL Connector/J 8.0.33
- BCrypt (`org.mindrot:jbcrypt:0.4`)
- Gson 2.10.1
- iTextPDF 5.5.13.3
- SLF4J + Logback

Testing:

- JUnit 5
- Mockito 5
- AssertJ
- H2 2.1.214

Frontend:

- JSP, HTML, CSS, vanilla JavaScript
- Font Awesome CDN
- Chart.js (admin dashboards/reports)

## Architecture

- MVC: Servlet controllers + JSP views
- DAO pattern: `BaseDAO` parent for DB access helpers
- Service layer for business logic
- Factory pattern: `DAOFactory`, `ServiceFactory`
- Singleton configs: `AppConfig`, `DatabaseConfig`

Main module counts (current tree):

- 58 Java source files under `src/main/java/com/oceanview`
- 17 controllers
- 10 DAOs
- 8 services
- 36 JSP pages under `src/main/webapp`
- 11 test classes

## Implemented Functional Areas

- Authentication: login, logout, register
- Dashboards: admin, staff, guest
- Room listing/search and admin room management
- Reservation creation and lifecycle actions (confirm/check-in/check-out/cancel)
- Staff check-in/check-out operations with JSON search/detail endpoints
- Reviews: guest submissions + admin moderation
- Offers: promo creation and promo code validation endpoint
- Admin user management (CRUD, status toggle, reset password)
- Admin settings page backed by `SettingsService`/`SettingsDAO` (requires `hotel_settings` table)
- Reports dashboard (admin page)
- Billing service + payment processing backend

## URL Map

Configured in `src/main/webapp/WEB-INF/web.xml`:

- `/login`, `/logout`, `/register`
- `/dashboard`
- `/guest/home`, `/guest/profile`
- `/room`, `/rooms`, `/admin/rooms`
- `/reservation`, `/booking`, `/staff/reservations`, `/admin/reservations`
- `/staff/checkin`, `/staff/checkout`
- `/review`, `/admin/reviews`
- `/offer`, `/admin/offers`
- `/report`, `/admin/reports`
- `/billing`
- `/settings`, `/admin/settings`
- `/admin/users`, `/admin/dashboard`

Action-driven servlets:

- Rooms: `action=view|list|search|available|add|edit|delete|updateStatus`
- Reservations: `action=new|view|list|create|cancel|confirm|checkin|checkout|update`
- Reviews: `action=myReviews|list|view|create|new|pending|update|approve|reject|respond|delete`
- Offers: `action=list|view|edit|delete|active|validate`
- Reports: `action=dashboard|revenue|occupancy|reservations|rooms`
- Billing: `action=list|view|viewBill|processPayment|refund`
- Users (admin): `action=create|update|delete|toggleStatus|resetPassword`
- Settings (admin): category update actions plus `createSetting|delete|changePassword|updateProfile|clearCache`

## Database

Schema files:

- `src/main/resources/database/schema.sql` (primary clean schema)
- `src/main/resources/database/triggers.sql` (standalone trigger file)
- `src/main/resources/database/migration_add_offer_fields.sql`
- `src/main/resources/database/migration_rooms_size_imageurl.sql`
- `src/main/resources/database/migration_room_prices_lkr.sql`
- `src/main/resources/database/seed-staff-test.sql` (test data + accounts)

Core tables in schema:

- `users`
- `guests`
- `rooms`
- `offers`
- `reservations`
- `payments`
- `reviews`
- `audit_logs`

### Important: settings table is missing from SQL scripts

Code uses a `hotel_settings` table (`SettingsDAO`) but no migration file is currently included for it.

If you need `/admin/settings` to persist data, create it manually:

```sql
CREATE TABLE IF NOT EXISTS hotel_settings (
    setting_id INT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    setting_key VARCHAR(120) NOT NULL UNIQUE,
    setting_value TEXT,
    setting_type ENUM('STRING','INTEGER','DECIMAL','BOOLEAN','JSON') NOT NULL DEFAULT 'STRING',
    description VARCHAR(255),
    is_editable TINYINT(1) NOT NULL DEFAULT 1,
    updated_by INT NULL,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_hotel_settings_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_hotel_settings_category (category)
);
```

## Quick Start

Prerequisites:

- JDK 11
- Maven 3.6+
- MySQL 8.0+
- Tomcat 10+ (Jakarta namespace)

1. Configure database connection in `src/main/resources/config/application.properties`.
2. Run schema:

```bash
mysql -u root -p < src/main/resources/database/schema.sql
```

3. Optional migrations:

```bash
mysql -u root -p oceanview_resort < src/main/resources/database/migration_rooms_size_imageurl.sql
mysql -u root -p oceanview_resort < src/main/resources/database/migration_add_offer_fields.sql
mysql -u root -p oceanview_resort < src/main/resources/database/migration_room_prices_lkr.sql
```

4. Optional test seed:

```bash
mysql -u root -p oceanview_resort < src/main/resources/database/seed-staff-test.sql
```

5. Build:

```bash
mvn clean package
```

6. Deploy WAR:

- Copy `target/oceanview-resort.war` to Tomcat `webapps`
- Open `http://localhost:8080/oceanview-resort`

## Seed Accounts

From `seed-staff-test.sql`:

- Admin: `admin` / `Admin@1234`
- Staff: `staff` / `Staff@1234`
- Guest: `testguest` / `password123`

## Build and Test Commands

```bash
mvn clean package
mvn test
mvn jacoco:report
```

Note: no Maven Wrapper (`mvnw`) is included in this repo.

## Configuration Notes

Primary config file: `src/main/resources/config/application.properties`

Key groups:

- `db.*` connection and pool
- `session.timeout`
- `upload.*`
- `security.*`
- `billing.*`
- `pagination.*`
- `features.*`

Currency:

- `billing.currency=LKR`
- `billing.currency.symbol=Rs.`

Legacy constants still contain USD defaults (`Constants.CURRENCY`, `NumberUtil.formatCurrency`), so prefer config-driven values in new work.

## Testing Coverage Areas

Current test classes cover:

- Utilities (`DateUtil`, `NumberUtil`, `PasswordUtil`, `ValidationUtil`)
- Models (`User`, `Reservation`)
- Services (`AuthenticationService`, `ReservationService`, `RoomService`)
- DAO (`UserDAOTest`)
- Reservation workflow integration (`ReservationIntegrationTest`)

## Known Gaps and Inconsistencies

Documented from current source:

- Several servlet forwards target JSP files not present in `src/main/webapp/views`:
  - billing pages (`/views/*/billing/*.jsp`, `/views/billing/*.jsp`)
  - report detail pages (`/views/reports/*.jsp`)
  - room detail/list pages (`/views/rooms/*.jsp`)
  - admin offer form/details pages (`/views/admin/offer-form.jsp`, `/views/offer-details.jsp`)
  - guest offers page (`/views/guest/offers.jsp`)
  - admin room form (`/views/admin/room-form.jsp`)
- Many UI links point to routes not mapped in `web.xml`:
  - `/about`, `/contact`, `/forgot-password`
  - `/staff/dashboard`, `/guest/dashboard` (mapped flow uses `/dashboard` and `/guest/home`)
- `hotel_settings` SQL migration is absent although settings code is active.
- `schema-jdbc.sql` is not a clean minimal schema file; it includes mixed inserts/seed/update snippets. Use `schema.sql` + explicit migrations for clean setup.
- `GuestDAO.findCompletedByGuestId` currently queries status `COMPLETED` while schema uses `CHECKED_OUT`.
- One staff view (`views/staff/search.jsp`) references `bootstrap.Modal`, but Bootstrap is not included.

## Repository Layout

```text
src/main/java/com/oceanview/
  config/        AppConfig, DatabaseConfig
  controller/    Servlet controllers
  dao/           DAO classes (extend BaseDAO)
  factory/       DAOFactory, ServiceFactory
  filter/        Auth, authorization, logging, encoding filters
  model/         Entity and enum models
  service/       Business services
  util/          Constants and utility classes

src/main/resources/
  config/application.properties
  database/*.sql

src/main/webapp/
  assets/
  views/
  WEB-INF/web.xml

src/test/
  java/com/oceanview/*
  resources/test-application.properties
```


