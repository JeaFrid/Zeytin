## 1.0.0

- Initial version.

## 2.1.0

- Added an automatic database backup algorithm.
- Made fundamental changes to token exchange.
- Restricted plain text from circulating in the payload.
- Implemented some changes to the engine. Ensured trucks are loaded at startup.
- Ngnix configuration has been fixed.
- Sockets compatible with Livekit have been designed.
- Compatibility with Livekit and Ngnix has been ensured.

## 2.5.0

- Engine updated

## 2.6.0

- This update has fundamentally changed the Zeytin Database Engine. However, your data will not be affected, and you won’t need to update your code. I updated the engine solely to add new features and make it more secure.

- Email Capabilities Added! Your Zeytin server can now send emails. You can configure your SMTP settings by reviewing the `config.dart` file. Additionally, you can set this up quickly and easily using the Flutter package.

## 2.7.0

- All relevant (and necessary) unit tests have been added.

- The database manager, `server/runner.dart`, is now responsible for creating and managing accounts (Truck files).

- The `/truck/create` route for account creation has been removed. Since this process could be “extremely dangerous,” it can only be performed with the `runner.dart` permission, which is restricted to localhost.

- A new terminal application named `server/db_manager.dart` has been developed. This application allows administrators to exercise full control over the database.

- The documentation has been updated.

- Everyone was served a cup of coffee.

- The fish were fed.

## 2.8.0

- Multi-platform installation support added! Zeytin can now be installed on Fedora/RHEL/CentOS, Arch Linux, macOS, and Windows with dedicated installation scripts.

- Platform-specific installation scripts have been organized under `server/platforms/` directory for better maintainability.

- Documentation significantly enhanced with a detailed Table of Contents featuring 3-level deep navigation for easier access to specific topics.

- All language versions of documentation (English, German, Hindi, Turkish) have been updated with the new structure.

- The README now includes comprehensive subsections for API endpoints, security features, and server management tools.

- Installation instructions for all supported platforms have been added to the Quick Install section.

- Someone organized the toolbox. Finally.

- The plants were watered (they were getting thirsty).
