# Zeytin <🫒/>

**Zeytin** is a high-performance, scalable, and security-focused next-generation server solution that eliminates external database dependencies. Leveraging the power of the Dart language, it operates as both a web server and a custom NoSQL database engine.

In traditional backend architectures, the server and database exist as separate layers, leading to network latency and management challenges. Zeytin breaks down these barriers by embedding the database engine directly into the server's memory and processing threads.

## Why Zeytin?

It provides a simple yet powerful response to the complex infrastructure problems encountered in modern application development.

### 1. Self-Sufficient
When using Zeytin, there is no need to install, configure, or manage external services like MongoDB, PostgreSQL, or Redis. Inside Zeytin, there is a custom disk-based and ACID-compliant database engine we call **Truck**. The moment you complete the installation, your database is ready.

### 2. Isolation Architecture and High Performance
The system is built upon Dart's **Isolate** technology. Every user database (Truck) runs in a thread that is independent and isolated from the main server. This ensures that heavy data writing operations by one user never block the server from responding to other users. Thanks to the custom **Binary Encoder**, data takes up much less space than JSON format and is processed much faster.

### 3. Internal Firewall: Gatekeeper
Zeytin leaves nothing to chance regarding security. It continuously analyzes server traffic with the **Gatekeeper** module:
* Automatically switches to Sleep Mode during instant peak loads.
* Blocks spam requests by applying IP-based rate limiting.
* Detects malicious attempts and bans the relevant IP addresses.

### 4. End-to-End Encryption
Your data is safe not just on the disk, but also while being transported over the network. Zeytin encrypts critical data traffic between the client and server using the **AES-CBC** standard with keys derived from the user's password. Even the database administrator cannot see the content of the data without knowing the user password.

### 5. Real-Time and Multimedia Support
It doesn't just store data; it also offers live features required by modern applications:
* **Watch:** You can listen to changes in the database instantly via WebSocket.
* **Call:** Manages voice and video call rooms thanks to internal LiveKit integration.

---

## Architectural Overview

Zeytin's data structure is constructed with real-world logistics logic and consists of three main layers:

* **Truck:** The main database file assigned to each user. It is physically isolated from other users.
* **Box:** Tables used to categorize data (e.g., products, orders).
* **Tag:** The unique key used to access data.

## Quick Install

A single command is enough to install Zeytin on your server and configure all dependencies (Dart, Docker, Nginx, SSL).

Run this once on your server:

```bash
wget -qO install.sh https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/install.sh && sudo bash install.sh
```


# 1. Introduction and Architecture

Zeytin is much more than standard server software. While it may look like a backend offering REST API services from the outside, a custom, disk-based, high-performance NoSQL database engine written entirely in Dart runs at its heart.

Usually, in modern backend architectures, the database and server are separate layers. In the Zeytin structure, this distinction does not exist. The database engine is embedded right into the server, its memory, and its processes. This allows it to reach incredible speeds with direct memory and disk access, without network latency.

To understand the Zeytin architecture, you need to recognize the three fundamental building blocks that make up the system: **Truck**, **Box**, and **Tag**.

## Data Hierarchy

The system's data storage logic has a hierarchy that can be associated with real life. At the very top is Zeytin, which is the system itself; below that are the Truck structures, which are isolated storage units; inside these units are categories, namely Box areas; and finally, the Tag and Value, which are the data itself.

```text
ZEYTIN (Server)
└── TRUCK (Truck / Database File)
    ├── BOX (Box / Collection)
    │   ├── TAG (Label / Key): VALUE (Value / Data)
    │   ├── TAG: VALUE
    │   └── ...
    └── BOX
        └── ...
```

### 1. Truck

Truck is the largest and most important building block of the Zeytin architecture. It corresponds to the concept of a Database in classic database systems. However, technically, it represents much more.

Each Truck physically consists of two files on the disk:
* **Data File (.dat):** The place where data is stored in a compressed binary format.
* **Index File (.idx):** The map holding the positions of data on the disk, meaning offset and length information.

**Isolation and Performance:**
Zeytin opens a separate Isolate, meaning an isolated processing thread, on the processor for every Truck created. This means that a heavy read or write operation performed by User A on their Truck will never slow down or lock User B's Truck structure. Each Truck has its own memory, its own cache, and its own processing queue.

When a user account is created in the system, a special Truck is actually allocated to that user. Thus, users' data is completely separated from each other physically and logically.

### 2. Box

The logical sections used to categorize data within Truck structures are called Boxes. This is similar to a Table in SQL databases or a Collection structure in MongoDB.

You can put an unlimited number of Boxes inside a Truck. For example, the following Box areas might exist inside a Truck created for an e-commerce user:
* `products`
* `orders`
* `settings`

Box structures are not physically separate files; they are logical labels within the Truck file indicating which group the data belongs to. This way, when searching in the `products` box, the system does not waste time with data in the `orders` box.

### 3. Tag

It is the unique key used to access data. Every piece of data within a Box must have its own unique Tag value. It works with the logic of a Primary Key in SQL structures or the Key in Key-Value systems.

When the Zeytin engine wants to read data, it follows the Truck, Box, and Tag path respectively. Thanks to the indexing system, no matter how large the database size is, finding a Tag value and retrieving the data takes milliseconds. This is because the system does not scan the entire file; it goes directly to the disk coordinate of the Tag value and reads only that part.

---

## Example Scenario: Data Flow

Let's examine how the system works through an example. Let's say a user wants to save Theme information to the Settings box.

1.  **Request Arrives:** The user wants to write the data `{ "mode": "dark" }` with the `theme` tag to the `settings` box.
2.  **Routing:** The main Zeytin class detects which **Truck**, i.e., which identity ID, this user is performing the operation with.
3.  **Proxy Communication:** The main server does not write the data directly to the disk. Instead, via `TruckProxy`, it sends a message to the isolated thread running specifically for that Truck.
4.  **Engine Engages:**
    * The isolated processor receives the message.
    * It compresses the data with a special **Binary Encoder** and translates it into machine language.
    * It appends the data to the very end of the `.dat` file.
    * It saves the new location of the data in the file to the `.idx` file.
    * Finally, it writes the data into the **LRU Cache** in memory for fast access.

Thanks to this architecture, Zeytin offers both the persistence of a file system and the speed of in-memory databases simultaneously.


# 2. Installation and Configuration

Zeytin is a system that integrates deeply with the machine it runs on. Just running a code file is not enough; parts like the database engine's disk access, the media server's Docker connection, and Nginx configuration for communication with the outside world need to come together.

To handle this complex process with a single line, we prepared an advanced automation script named `server/install.sh`. This script takes your server from scratch and makes it completely ready for a production environment.

## Automatic Installation Script

To start the installation, simply run the `server/install.sh` file on your server as an authorized user. The script is optimized for Debian and Ubuntu-based systems.

```bash
wget -qO install.sh https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/install.sh && sudo bash install.sh
```


When you issue this command, the script follows these steps respectively:

### 1. Basic Dependencies and Dart
First, the system updates and installs basic packages like `git`, `curl`, `unzip`, `openssl`, and `nginx`. Then, it checks if the Dart language is installed on the machine. If not installed, it adds Google's official repositories to the system and completes the Dart SDK installation.

Finally, it enters the project directory, runs the `dart pub get` command, and downloads all libraries specified in the `pubspec.yaml` file (shelf, crypto, encrypt, etc.), making the project ready to compile.

### 2. LiveKit and Docker Integration (Optional)
The script will ask you the following question:
`Do you want to enable Live Streaming & Calls?`

If you say **y** (yes), the system's media capabilities are activated:
* **Docker Check:** If Docker is not on the machine, the latest Docker version is automatically installed.
* **Container Setup:** The necessary Docker image for the LiveKit server is downloaded, and a container named `zeytin-livekit` is started.
* **Key Generation:** The script uses `openssl` to generate a random and secure API Key and Secret Key.
* **Config Update:** This is the most impressive part. The script takes these generated keys and the server's external IP address, opens the `lib/config.dart` file in your source code, and automatically updates the relevant lines. You don't need to open the file and manually adjust settings.

### 3. Nginx and SSL Configuration (Optional)
The script asks you the second critical question:
`Do you want to install and configure Nginx with SSL?`

This stage is for safely opening your application to the outside world. If you say **y**:
* **Domain Definition:** It asks you for a domain name (e.g., api.example.com) and an email address for SSL notifications.
* **Reverse Proxy:** It creates a special configuration file for Nginx. This setting captures requests coming to ports 80 and 443 and forwards them to the Zeytin server running on port 12852 in the background. Necessary header settings (Upgrade, Connection) for WebSocket connections to not drop are automatically added.
* **Isolated Certbot:** It sets up a virtual Python environment (venv) under `/opt/certbot` so as not to mess up your system's Python libraries. It installs Certbot in this isolated area.
* **SSL Certificate:** It obtains a free SSL certificate via Let's Encrypt and updates Nginx settings to force HTTPS traffic.

## Dependency Management

The packages required for the system to work are defined in the `pubspec.yaml` file. Zeytin's power comes from using the right packages for the right purpose:

* **shelf & shelf_router:** Used for the server to listen to and route HTTP requests. It is the skeleton of the web server.
* **shelf_web_socket:** Manages socket connections for real-time data flow and the "Watch" mechanism.
* **encrypt:** Provides the AES encryption algorithms used by the `ZeytinTokener` class.
* **dart_jsonwebtoken:** Creates JWT tokens to establish secure communication with LiveKit.
* **dio:** Allows the server to make HTTP requests to other services within itself or in the outside world.

Once the installation is complete, you are ready to use the `server/runner.dart` tool to manage the server.


# 3. Storage Engine

The most fundamental feature that distinguishes Zeytin from other server solutions is that it possesses its own database engine. This engine manages data on the operating system's file system using a special binary format and high-performance isolation techniques.

Located in the system's `lib/logic/engine.dart` file, this structure is built upon four main mechanisms: **Binary Encoder**, **Persistent Index**, **Isolate Architecture**, and **Compaction**.

## 3.1. Binary Data Format

Zeytin does not use text-based formats like JSON or XML when writing data to the disk. Instead, to save disk space and increase read-write speed, it uses a custom protocol managed by the `BinaryEncoder` class.

Data is processed using `ByteData` and `Uint8List` and is packed in Little Endian order. Every data block starts with `0xDB`, the Magic Byte, to ensure data integrity. This magic byte helps the engine detect data corruption.

The structure of a data block on the disk is as follows:

| MAGIC (1 Byte) | BOX_ID_LEN (4 Byte) | BOX_ID (N Byte) | TAG_LEN (4 Byte) | TAG (N Byte) | DATA_LEN (4 Byte) | DATA (N Byte) |
|----------------|---------------------|-----------------|------------------|--------------|-------------------|---------------|
| 0xDB           | 0x00000008          | "settings"      | 0x00000005       | "theme"      | 0x0000000E        | {Binary Map}  |


Thanks to this structure, when the engine goes to a random location on the disk, it can understand flawlessly where the data starts, which box and tag it belongs to, and where the data ends.

Supported data types and their identity numbers in the system are:
* `NULL` (0)
* `BOOL` (1)
* `INT` (2) - 64-bit integer
* `DOUBLE` (3) - 64-bit floating-point number
* `STRING` (4) - UTF8 encoded text
* `LIST` (5) - Dynamic lists
* `MAP` (6) - Key-value maps

## 3.2. Persistent Indexing

The biggest problem of database engines is that search time increases as data grows. Zeytin solves this problem with the `PersistentIndex` class.

The system maintains an index file (`.idx`) simultaneously with the data file (`.dat`). This index file stores not the data itself, but the **address** (offset) and **size** (length) of the data on the disk.

When the server starts up or a Truck is loaded, this index file is taken entirely into memory, i.e., RAM. Thus, when you want to access data, the system does not scan the disk; it gets the coordinates of the data directly from the map in memory and reads only that point from the disk. This ensures that access time remains at the millisecond level even if the data size is gigabytes.

A sample index map looks like this in memory:

```text
Box: "users"
  └── Tag: "user_123" -> [Offset: 1024, Length: 256]
  └── Tag: "user_456" -> [Offset: 1280, Length: 512]
```

## 3.3. Isolate and Proxy Architecture

By its nature, the Dart language has a single-threaded structure. Heavy disk operations (I/O) can block the main thread and cause the server to fail to respond to other incoming requests. Zeytin uses a structure similar to the **Actor Model** to overcome this bottleneck.

Each user database, or Truck, runs inside a specific **Isolate** independent of the main server. Isolates do not share memory; they communicate by messaging each other.

1.  **TruckProxy:** Runs on the main server side. Receives requests and converts them into a message queue.
2.  **SendPort / ReceivePort:** The communication bridge between the main server and the isolated engine.
3.  **TruckIsolate:** The engine running in the background with completely separated memory and processing queue.

Thanks to this architecture, a very heavy bulk write operation performed by a user in the database never slows down other users' operations or instant video calls on the server.

## 3.4. Append-Only Writing and Compaction

The Zeytin engine works with the **Append-Only** logic to ensure data security. When you update or delete data, the old data is not immediately deleted from the disk. Instead, the new state of the data or a sign that it has been deleted is added to the very end of the file, and the index is updated.

This method minimizes the risk of data loss but causes the data file to swell over time and "dead" data to accumulate inside.

To prevent this, there is an automatic **Compaction** mechanism within the `Truck` class:
1.  The system is triggered after every 500 write operations.
2.  The engine creates a temporary file (`_temp.dat`).
3.  It transfers only the data that is **active and valid**, i.e., whose final state is recorded in the index, to this new file.
4.  Old and unnecessary data are left behind.
5.  When the process is finished, the old file is deleted, and the new file is named as the main data file.

Since this process takes place in the background and in an isolated manner, the system cleans and optimizes itself without interruption.


# 4. Security and Authentication

Zeytin is built upon two main mechanisms that address security from the outermost layer of the application to the deepest form of data storage: **Gatekeeper** and **Tokener**.

In this section, we will examine the Gatekeeper structure that protects your server from malicious attacks and the Tokener mechanism that ensures your data is transported encrypted over the network.

## 4.1. Gatekeeper: The First Line of Defense

Gatekeeper is the first component that greets every request coming to your server. It works like a bouncer at a nightclub; it decides who can enter, who cannot, and how frequently they can make requests.

Located in the `lib/logic/gatekeeper.dart` file, this structure provides active protection against the following threats:

### DoS and DDoS Protection (Sleep Mode)
Zeytin instantly tracks the total number of requests coming to the server using a global counter. If the `globalDosThreshold` (default: 50,000 requests) is exceeded, the system automatically puts itself into **Sleep Mode**.

* **Response:** The server returns a 503 Service Unavailable error.
* **Message:** "Be quiet! I'm trying to sleep here."
* **Duration:** The system rejects all new requests for a specified duration (default: 5 minutes) and lets the processor cool down.

### Intelligent Rate Limiting
A separate activity record is kept for each IP address. Gatekeeper applies two different rate limits based on IP:

1.  **General Request Limit:** If an IP address sends more requests than the `generalIpRateLimit5Sec` (default: 100) value within 5 seconds, it is temporarily blocked and receives a 429 Too Many Requests error.
2.  **Token Creation Limit:** The login and token acquisition endpoint (`/token/create`) is more strictly protected against brute-force attacks. Only 1 request per second can be sent to this endpoint.

### IP Management (Blacklist & Whitelist)
You can perform static IP management via the `config.dart` file:
* **Blacklist:** IP addresses added here cannot access the server under any circumstances.
* **Whitelist:** IP addresses added here (e.g., local network or admin IP) can perform operations without getting stuck in rate limits.

---

## 4.2. Token Management and Sessions

Instead of behaving like a stateless REST API, Zeytin uses session tokens that are time-limited and kept in memory.

### Token Lifecycle
When a user sends a request to the `/token/create` address with their email and password, the system verifies this information and creates a temporary UUID (Unique Identity) in memory.

* **Lifespan:** Tokens are valid for only **2 minutes (120 seconds)** from the moment they are created.
* **Security:** Being this short-lived ensures that if the token is stolen, the attacker has a very limited time to perform operations.
* **Refresh:** The client side must request a new token every 2 minutes or immediately before performing an operation.

### Multi-Account Restriction
Gatekeeper limits the number of Trucks (accounts) that can be opened from the same IP address. By default, an IP address can create at most 20 different accounts. If this limit is exceeded, that IP address is automatically banned.

---

## 4.3. Tokener: End-to-End Encryption

Critical data operations on Zeytin (CRUD operations and WebSocket streams) do not transport data as plain text (JSON). Instead, they transport it in encrypted packets using the **AES-CBC** algorithm. The class managing this process is `ZeytinTokener`.

### Encryption Logic
Every user's encryption key is derived from their own login password. This means that even the database administrator cannot decrypt the content of the data by listening to network traffic without knowing the user password.

**Data Packet Structure:**
Encrypted data consists of two parts: Initialization Vector (IV) and Ciphertext, with a colon (`:`) between them.

Format: `IV_BASE64:CIPHERTEXT_BASE64`

### Example Request and Response

Let's assume you send a request to the `/data/get` endpoint to read data.

**Client Request:**
The client sends the `box` and `tag` information not openly, but encrypted.
```json
{
  "token": "a1b2c3d4-...",
  "data": "r5T8...IV_BASE64...:e9K1...CIPHERTEXT..." 
  // The "data" parameter is an encrypted JSON object: {"box": "settings", "tag": "theme"}
}
```

**Server Response:**
The server finds the data, reads it, and returns it encrypted again.
```json
{
  "isSuccess": true,
  "message": "Oki doki!",
  "data": "m7Z2...IV_BASE64...:p4L9...CIPHERTEXT..."
  // When decrypted: {"mode": "dark", "fontSize": 14}
}
```

### Client-Side Integration
If you are developing a client application that will talk to Zeytin, you need to adapt the logic in the `ZeytinTokener` class to your own language.

1.  **Key Derivation:** Hash the user's password with SHA-256. The resulting byte array is your AES key.
2.  **Encryption:** Encrypt the JSON data you will send in AES-CBC mode using a randomly generated 16-byte IV. Create the `IV:EncryptedData` string as a result.
3.  **Decryption:** Split the response coming from the server from the `:` character. The first part is the IV, the second part is the encrypted data. Decrypt the data using the same key.

Thanks to this structure, data rests as binary in the database and travels encrypted over the network. Only the client with a valid session and knowledge of the password can make the data meaningful.


# 5. API Reference

To keep data security at the highest level, Zeytin communicates with encrypted data packets instead of standard JSON at most of its endpoints. Therefore, understanding the concept of "Encrypted Data" is vital before using the API.

Unless otherwise stated, in all requests under **CRUD**, **Call**, and **Watch**, the `data` parameter must be a JSON string encrypted using the AES key derived from the user's password.

---

## 5.1. Account and Session Management

These endpoints are the gateway to the database engine. Data here is sent in open JSON format, without encryption.

### Creating a New Account (Truck)
Creates a new user space (Truck) in the system.

* **Endpoint:** `POST /truck/create`
* **Body:**
    ```json
    {
      "email": "example@mail.com",
      "password": "strong_password"
    }
    ```
* **Response:** Returns the created Truck ID if successful.

### Account ID Query
Verifies email and password and retrieves the user's Truck ID.

* **Endpoint:** `POST /truck/id`
* **Body:** Email and password (same as above).

### Token Creation (Log In)
Generates the temporary session key (Token) required to perform operations. This token is valid for 2 minutes (120 seconds).

* **Endpoint:** `POST /token/create`
* **Body:**
    ```json
    {
      "email": "example@mail.com",
      "password": "strong_password"
    }
    ```
* **Response:** `{"token": "token-in-uuid-format"}`

### Token Deletion (Log Out)
Invalidates an active token before it expires.

* **Endpoint:** `DELETE /token/delete`
* **Body:** Email and password.

---

## 5.2. Data Operations (CRUD)

All requests in this section take two parameters:
1.  `token`: The valid session key obtained from `/token/create`.
2.  `data`: The **encrypted** string containing the parameters of the requested operation.

> **Note:** In the examples below, the content of `data` is shown in its (open) state before encryption. In a real request, this JSON must be encrypted with `ZeytinTokener` and sent.

### Add / Update Data
Writes data to the specified box (Box) and tag (Tag). If the tag exists, it updates; if not, it creates.

* **Endpoint:** `POST /data/add`
* **Encrypted Data Content:**
    ```json
    {
      "box": "settings",
      "tag": "theme",
      "value": { "mode": "dark", "color": "blue" }
    }
    ```

### Bulk Data Addition (Batch)
Writes multiple pieces of data to a single box at once. Should be preferred for performance.

* **Endpoint:** `POST /data/addBatch`
* **Encrypted Data Content:**
    ```json
    {
      "box": "products",
      "entries": {
        "product_1": { "name": "Laptop", "price": 5000 },
        "product_2": { "name": "Mouse", "price": 100 }
      }
    }
    ```

### Read Data (Single)
Retrieves data in a specific tag.

* **Endpoint:** `POST /data/get`
* **Encrypted Data Content:** `{ "box": "settings", "tag": "theme" }`
* **Response:** Returns encrypted data. Must be decrypted on the client side.

### Read Box (All)
Retrieves all data in a box. Should be used carefully; the process may take a long time in large boxes.

* **Endpoint:** `POST /data/getBox`
* **Encrypted Data Content:** `{ "box": "products" }`

### Delete Data
Deletes a specific tag and its data.

* **Endpoint:** `POST /data/delete`
* **Encrypted Data Content:** `{ "box": "settings", "tag": "theme" }`

### Delete Box
Completely clears a box and all data inside it.

* **Endpoint:** `POST /data/deleteBox`
* **Encrypted Data Content:** `{ "box": "history_logs" }`

### Existence Checks
Lightweight endpoints that check if data exists. They return only `true/false` information encrypted, not the data itself.

* **Tag Exists?:** `POST /data/existsTag` -> `{ "box": "...", "tag": "..." }`
* **Box Exists?:** `POST /data/existsBox` -> `{ "box": "..." }`
* **Content Check:** `POST /data/contains` -> `{ "box": "...", "tag": "..." }` (Verifies physical existence of data in memory or disk).

### Search and Filtering
* **Prefix Search (Search):** Searches whether the value in a field starts with a specific word (prefix).
    * **Endpoint:** `POST /data/search`
    * **Encrypted Data:** `{ "box": "users", "field": "name", "prefix": "Ahmet" }`

* **Exact Match (Filter):** Retrieves records where the value in a field matches exactly.
    * **Endpoint:** `POST /data/filter`
    * **Encrypted Data:** `{ "box": "users", "field": "age", "value": 25 }`

---

## 5.3. File Storage (Storage)

File upload operations are done in standard `multipart/form-data` format. Encryption is not used, but a Token is mandatory.

### Upload File
* **Endpoint:** `POST /storage/upload`
* **Method:** Multipart Form Data
* **Fields:**
    * `token`: Valid session key (String).
    * `file`: File to be uploaded (Binary).
* **Restrictions:** Executable files like `.exe`, `.php`, `.sh`, `.html`, etc., are rejected for security reasons.

### Download / View File
Uploaded files are served publicly.

* **Endpoint:** `GET /<truckId>/<fileName>`
* **Example:** `GET /a1b2-c3d4.../profile_pic.jpg`

---

## 5.4. Live Monitoring (Watch - WebSocket)

Allows clients to listen to changes in the database (add, delete, update) instantly.

* **Endpoint:** `ws://server-address/data/watch/<token>/<boxId>`
* **Parameters:** Valid `token` and the desired `boxId` to watch must be specified in the URL.
* **Event Structure:** Messages coming from the server contain JSON in the following format:
    ```json
    {
      "op": "PUT", // Operation type: PUT, UPDATE, DELETE, BATCH
      "tag": "changed_data_tag",
      "data": "ENCRYPTED_DATA", // Encrypted new value
      "entries": null // Filled only in batch operations
    }
    ```

---

## 5.5. Call and Broadcast (Call - LiveKit)

Zeytin works integrated with the LiveKit server to provide necessary "Room" management for voice and video calls.

### Join Room (Get Token)
Generates a LiveKit access token to start a call or join an existing room.

* **Endpoint:** `POST /call/join`
* **Encrypted Data Content:**
    ```json
    {
      "roomName": "meeting_room_1",
      "uid": "user_123"
    }
    ```
* **Response:** Returns the LiveKit server address and JWT token encrypted.

### Room Status Check
Checks if there is an active call in a room.

* **Endpoint:** `POST /call/check`
* **Encrypted Data Content:** `{ "roomName": "meeting_room_1" }`
* **Response:** Returns `isActive` (boolean) value encrypted.

### Live Room Tracking (Stream)
Continuously tracks the activity status of a room via WebSocket.

* **Endpoint:** `ws://server-address/call/stream/<token>?data=ENCRYPTED_DATA`
* **Parameters:**
    * `token` in the URL path.
    * `data` as a Query parameter: `{ "roomName": "..." }` (Encrypted).
* **Behavior:** When the room status changes (when someone enters or the last person leaves), the server sends an instant notification.


# 6. Server Management

Zeytin is not just software; it is a living system. We developed an interactive management panel named **Runner** so you don't have to deal with complex Linux commands (kill, nohup, tail, etc.) to manage this system.

The `server/runner.dart` file is your server's cockpit. All operational tasks like starting, stopping, updating, and monitoring logs are done from here.

## Starting Runner

When you connect to your server via SSH, simply enter the following command to open the management interface:

```bash
dart server/runner.dart
```

You will face a colored and numbered menu. We have detailed below what the options in this menu serve and what they do in the background.

---

## 6.1. Execution Modes

Two different options are offered to start the system. It is important to know which one to use in which situation.

### 1. Start Test Mode
This option starts the server immediately in the current terminal window without compiling.
* **Use Case:** Use this if you made changes to the code and want to test quickly.
* **Behavior:** When you close the terminal or press `CTRL+C`, the server also closes. It prints errors and outputs directly to the screen.
* **LiveKit Check:** Checks if the Docker container is running before starting; if closed, it automatically opens it.

### 2. Start Live Mode
This option prepares the server for a real production environment.
* **Compilation:** Converts the Dart code into machine language (in `.exe` format), creating an optimized file. This way, the server runs much faster and consumes less memory.
* **Background Operation:** Throws the server into the background with the `nohup` command. Even if you cut your SSH connection, the server continues to run.
* **Logs:** Writes all outputs to the `zeytin.log` file.
* **PID Tracking:** Saves the ID number of the running process to the `server.pid` file. This way, you can easily stop the server later.

---

## 6.2. Monitoring and Control

You can use these options to track the status of the server while it is running or to intervene.

### 3. Watch Logs
It is for seeing what the server running in the background (Live Mode) is doing instantly. It runs the `tail -f zeytin.log` command. You can press `CTRL+C` to stop the text flowing on the screen; this operation does not close the server, it only exits the monitoring screen.

### 4. Stop Server
Safely closes the running Zeytin server. Runner first looks at the `server.pid` file and terminates the relevant process. If the file does not exist or has been deleted, it forcibly cleans all Zeytin processes in the system.

---

## 6.3. Maintenance and Infrastructure Operations

These are necessary tools to maintain the system's currency and health.

### 6. UPDATE SYSTEM
Use this option when a new update is published on the GitHub repository. This process does the following respectively:
1.  Takes a backup of your existing `config.dart` file. (Your settings are not lost)
2.  Downloads the newest codes to the server with the `git pull` command.
3.  Restores the backed-up configuration file.
4.  Downloads the newly added libraries with `dart pub get`.
5.  You need to restart the server when the process is finished.

### 7. Clear Database & Storage
This option is **dangerous**. It stops the server and permanently deletes all user data, files, and indices inside the `zeytin/` folder. Use it when you want to make a clean start from scratch.

### 5. UNINSTALL SYSTEM
The most dangerous option. It stops the server and deletes the entire project folder from the disk. There is no turning back.

---

## 6.4. Nginx Management

If you did not make the SSL and Domain settings during the installation phase or want to change them, you can use this menu.

### 8. Nginx & SSL Setup
Triggers the `install.sh` file again. Used to define a new domain or obtain an SSL certificate.

### 9. Remove Nginx Config
Deletes the Nginx setting files and shortcuts created for Zeytin, then restarts the Nginx service. Your server no longer responds to the outside world (ports 80/443), it only works from the local port (12852).