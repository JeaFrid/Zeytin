
# Zeytin <🫒/>

**Zeytin**, harici veritabanı bağımlılıklarını ortadan kaldıran, yüksek performanslı, ölçeklenebilir ve güvenlik odaklı yeni nesil bir sunucu çözümüdür. Dart dilinin gücünü arkasına alarak hem bir web sunucusu hem de özel bir NoSQL veritabanı motoru olarak çalışır.

Geleneksel backend mimarilerinde sunucu ve veritabanı ayrı katmanlar halindedir ve bu durum ağ gecikmelerine, yönetim zorluklarına yol açar. Zeytin, veritabanı motorunu doğrudan sunucunun belleğine ve işlem süreçlerine gömerek bu bariyerleri yıkar.

## Neden Zeytin?

Modern uygulama geliştirmede karşılaşılan karmaşık altyapı sorunlarına basit ve güçlü bir yanıt verir.

### 1. Kendi Kendine Yeter
Zeytin kullanırken MongoDB, PostgreSQL veya Redis gibi harici servisleri kurmanıza, yapılandırmanıza veya yönetmenize gerek yoktur. Zeytin'in içinde **Truck** adını verdiğimiz, disk tabanlı ve ACID uyumlu çalışan özel bir veritabanı motoru bulunur. Kurulumu yaptığınız anda veritabanınız da hazırdır.

### 2. İzolasyon Mimarisi ve Yüksek Performans
Sistem, Dart dilinin **Isolate** teknolojisi üzerine kuruludur. Her kullanıcı veritabanı (Truck), ana sunucudan bağımsız ve izole bir iş parçacığında çalışır. Bu sayede bir kullanıcının yaptığı ağır veri yazma işlemi, sunucunun diğer kullanıcılara yanıt vermesini asla engellemez. Özel **Binary Encoder** sayesinde veriler JSON formatından çok daha az yer kaplar ve çok daha hızlı işlenir.

### 3. Dahili Güvenlik Duvarı: Gatekeeper
Zeytin, güvenlik konusunu şansa bırakmaz. **Gatekeeper** modülü ile sunucu trafiğini sürekli analiz eder:
* Anlık yoğunlukta otomatik Uyku Moduna geçer.
* IP tabanlı hız sınırlaması uygulayarak spam istekleri engeller.
* Kötü niyetli girişimleri tespit edip ilgili IP adreslerini yasaklar.

### 4. Uçtan Uca Şifreleme
Verileriniz sadece diskte değil, ağ üzerinde taşınırken de güvendedir. Zeytin, istemci ile sunucu arasındaki kritik veri trafiğini kullanıcının şifresinden türetilen anahtarlarla **AES-CBC** standardında şifreler. Veritabanı yöneticisi dahi, kullanıcı şifresini bilmeden verinin içeriğini göremez.

### 5. Gerçek Zamanlı ve Multimedya Desteği
Sadece veri saklamakla kalmaz, modern uygulamaların ihtiyacı olan canlı özellikleri de sunar:
* **Watch:** WebSocket üzerinden veritabanındaki değişiklikleri anlık olarak dinleyebilirsiniz.
* **Call:** Dahili LiveKit entegrasyonu sayesinde sesli ve görüntülü görüşme odalarını yönetir.

---

## Mimari Bakış

Zeytin'in veri yapısı, gerçek dünyadaki lojistik mantığıyla kurgulanmıştır ve üç ana katmandan oluşur:

* **Truck (Kamyon):** Her kullanıcıya atanan ana veritabanı dosyasıdır. Diğer kullanıcılardan fiziksel olarak izoledir.
* **Box (Kutu):** Verileri kategorize etmek için kullanılan tablolardır (Örn: ürünler, siparişler).
* **Tag (Etiket):** Veriye ulaşmak için kullanılan benzersiz anahtardır.

## Hızlı Kurulum

Zeytin'i sunucunuza kurmak ve tüm bağımlılıkları (Dart, Docker, Nginx, SSL) ayarlamak için tek bir komut yeterlidir.

Bunu sunucunuzda bir kez çalıştırın;

```bash
wget -qO install.sh [https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/install.sh](https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/install.sh) && sudo bash install.sh
```


# 1. Giriş ve Mimari

Zeytin, standart bir sunucu yazılımından çok daha fazlasıdır. Dışarıdan bakıldığında REST API servisleri sunan bir backend gibi görünse de, kalbinde tamamen Dart diliyle yazılmış, disk tabanlı ve yüksek performanslı özel bir NoSQL veritabanı motoru çalışır.

Genellikle modern backend mimarilerinde veritabanı ve sunucu ayrı katmanlar halindedir. Zeytin yapısında ise bu ayrım yoktur. Veritabanı motoru sunucunun tam içine, belleğine ve işlem süreçlerine gömülüdür. Bu sayede ağ gecikmesi olmadan, doğrudan bellek ve disk erişimi ile inanılmaz hızlara ulaşır.

Zeytin mimarisini anlamak için, sistemi oluşturan üç temel yapı taşını tanımanız gerekir: **Truck**, **Box** ve **Tag**.

## Veri Hiyerarşisi

Sistemin veri saklama mantığı gerçek hayatla bağdaştırılabilir bir hiyerarşiye sahiptir. En tepede sistemin kendisi olan Zeytin, onun altında izole edilmiş depolama birimleri olan Truck yapıları, bu birimlerin içindeki kategoriler yani Box alanları ve nihayetinde verinin kendisi olan Tag ve Value bulunur.

```text
ZEYTİN (Sunucu)
└── TRUCK (Kamyon / Veritabanı Dosyası)
    ├── BOX (Kutu / Koleksiyon)
    │   ├── TAG (Etiket / Anahtar): VALUE (Değer / Veri)
    │   ├── TAG: VALUE
    │   └── ...
    └── BOX
        └── ...
```

### 1. Truck

Truck, Zeytin mimarisinin en büyük ve en önemli yapı taşıdır. Klasik veritabanı sistemlerindeki Database kavramına karşılık gelir. Ancak teknik olarak çok daha fazlasını ifade eder.

Her Truck disk üzerinde fiziksel olarak iki dosyadan oluşur:
* **Veri Dosyası (.dat):** Verilerin sıkıştırılmış binary formatta saklandığı yerdir.
* **İndeks Dosyası (.idx):** Verilerin diskteki konumlarını, yani offset ve uzunluk bilgilerini tutan haritadır.

**İzolasyon ve Performans:**
Zeytin, oluşturulan her Truck için işlemci üzerinde ayrı bir Isolate yani izole edilmiş bir işlem parçacığı açar. Bu durum, A kullanıcısının Truck üzerinde yaptığı ağır bir okuma veya yazma işleminin, B kullanıcısının Truck yapısını asla yavaşlatmayacağı veya kilitlemeyeceği anlamına gelir. Her Truck kendi belleğine, kendi önbelleğine ve kendi işlem sırasına sahiptir.

Sistemde bir kullanıcı hesabı oluşturulduğunda, aslında o kullanıcıya özel bir Truck tahsis edilir. Böylece kullanıcıların verileri fiziksel ve mantıksal olarak birbirinden tamamen ayrılmış olur.

### 2. Box

Truck yapılarının içinde verileri kategorize etmek için kullanılan mantıksal bölümlere Box adı verilir. SQL veritabanlarındaki Tablo veya MongoDB üzerindeki Collection yapısına benzer.

Bir Truck içine sınırsız sayıda Box koyabilirsiniz. Örneğin bir e-ticaret kullanıcısı için oluşturulan Truck içinde şu Box alanları bulunabilir:
* `products`
* `orders`
* `settings`

Box yapıları fiziksel olarak ayrı dosyalar değildir; Truck dosyasının içinde verinin hangi gruba ait olduğunu belirten mantıksal etiketlerdir. Bu sayede `products` kutusunda arama yaparken, sistem `orders` kutusundaki verilerle zaman kaybetmez.

### 3. Tag

Veriye ulaşmak için kullanılan benzersiz anahtardır. Bir Box içindeki her veri parçasının kendine ait, eşsiz bir Tag değeri olmak zorundadır. SQL yapısındaki Primary Key veya Key-Value sistemlerindeki Key mantığıyla çalışır.

Zeytin motoru, bir veriyi okumak istediğinde sırasıyla Truck, Box ve Tag yolunu izler. İndeksleme sistemi sayesinde, veritabanı boyutu ne kadar büyük olursa olsun, bir Tag değerini bulup veriyi getirmek milisaniyeler sürer. Çünkü sistem tüm dosyayı taramaz, doğrudan Tag değerinin diskteki koordinatına gider ve sadece o kısmı okur.

---

## Örnek Senaryo: Veri Akışı

Sistemin nasıl çalıştığını bir örnek üzerinden inceleyelim. Diyelim ki bir kullanıcı Ayarlar kutusuna Tema bilgisini kaydetmek istiyor.

1.  **İstek Gelir:** Kullanıcı `settings` kutusuna, `theme` etiketiyle `{ "mode": "dark" }` verisini yazmak ister.
2.  **Yönlendirme:** Zeytin ana sınıfı, bu kullanıcının hangi **Truck** yani kimlik ID'si ile işlem yaptığını tespit eder.
3.  **Proxy İletişimi:** Ana sunucu, veriyi doğrudan diske yazmaz. Bunun yerine `TruckProxy` aracılığıyla, o Truck için özel çalışan izole iş parçacığına bir mesaj gönderir.
4.  **Motor Devreye Girer:**
    * İzole işlemci mesajı alır.
    * Veriyi özel bir **Binary Encoder** ile sıkıştırıp makine diline çevirir.
    * Veriyi `.dat` dosyasının en sonuna ekler.
    * Verinin dosyadaki yeni konumunu `.idx` dosyasına kaydeder.
    * Son olarak veriyi hızlı erişim için bellekteki **LRU Cache** içine yazar.

Bu mimari sayesinde Zeytin, hem dosya sisteminin kalıcılığını hem de bellek içi veritabanlarının hızını aynı anda sunar.



# 2. Kurulum ve Yapılandırma

Zeytin, üzerinde çalıştığı makineyle derinlemesine entegre olan bir sistemdir. Sadece bir kod dosyasını çalıştırmak yetmez; veritabanı motorunun disk erişimi, medya sunucusunun Docker bağlantısı ve dış dünyayla iletişim için Nginx yapılandırması gibi parçaların bir araya gelmesi gerekir.

Bu karmaşık süreci tek bir satırla halledebilmeniz için `server/install.sh` adında gelişmiş bir otomasyon scripti hazırladık. Bu script, sunucunuzu sıfırdan alıp tamamen üretim ortamına hazır hale getirir.

## Otomatik Kurulum Scripti

Kurulumu başlatmak için sunucunuzda `server/install.sh` dosyasını yetkili bir kullanıcı olarak çalıştırmanız yeterlidir. Script, Debian ve Ubuntu tabanlı sistemler için optimize edilmiştir.

```bash
wget -qO install.sh [https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/install.sh](https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/install.sh) && sudo bash install.sh
```


Bu komutu verdiğinizde script sırasıyla şu adımları izler:

### 1. Temel Bağımlılıklar ve Dart
Sistem öncelikle `git`, `curl`, `unzip`, `openssl` ve `nginx` gibi temel paketleri günceller ve kurar. Ardından makinede Dart dilinin kurulu olup olmadığını kontrol eder. Eğer kurulu değilse Google'ın resmi depolarını sisteme ekler ve Dart SDK kurulumunu tamamlar.

Son olarak proje dizinine girerek `dart pub get` komutunu çalıştırır ve `pubspec.yaml` dosyasında belirtilen tüm kütüphaneleri (shelf, crypto, encrypt vb.) indirerek projeyi derlemeye hazır hale getirir.

### 2. LiveKit ve Docker Entegrasyonu (İsteğe Bağlı)
Script size şu soruyu soracaktır:
`Do you want to enable Live Streaming & Calls?`

Eğer **y** (evet) derseniz, sistemin medya yetenekleri devreye girer:
* **Docker Kontrolü:** Makinede Docker yoksa otomatik olarak en güncel Docker sürümü kurulur.
* **Konteyner Kurulumu:** LiveKit sunucusu için gerekli Docker imajı indirilir ve `zeytin-livekit` adıyla bir konteyner başlatılır.
* **Anahtar Üretimi:** Script, `openssl` kullanarak rastgele ve güvenli bir API Anahtarı ve Gizli Anahtar (Secret Key) üretir.
* **Config Güncellemesi:** En etkileyici kısım burasıdır. Script, ürettiği bu anahtarları ve sunucunun dış IP adresini alır, kaynak kodunuzdaki `lib/config.dart` dosyasını açar ve ilgili satırları otomatik olarak günceller. Sizin dosyayı açıp elle ayar yapmanıza gerek kalmaz.

### 3. Nginx ve SSL Yapılandırması (İsteğe Bağlı)
Script size ikinci kritik soruyu sorar:
`Do you want to install and configure Nginx with SSL?`

Bu aşama, uygulamanızı dış dünyaya güvenli bir şekilde açmak içindir. **y** derseniz:
* **Domain Tanımlama:** Sizden bir alan adı (örneğin: api.ornek.com) ve SSL bildirimleri için bir e-posta adresi ister.
* **Ters Vekil (Reverse Proxy):** Nginx için özel bir yapılandırma dosyası oluşturur. Bu ayar, 80 ve 443 portlarına gelen istekleri yakalar ve arka planda 12852 portunda çalışan Zeytin sunucusuna iletir. WebSocket bağlantılarının kopmaması için gerekli başlık ayarları (Upgrade, Connection) otomatik eklenir.
* **İzole Certbot:** Sisteminizin Python kütüphanelerini bozmamak için `/opt/certbot` altında sanal bir Python ortamı (venv) kurar. Certbot'u bu izole alana yükler.
* **SSL Sertifikası:** Let's Encrypt üzerinden ücretsiz SSL sertifikasını alır ve Nginx ayarlarını HTTPS trafiğini zorunlu kılacak şekilde günceller.

## Bağımlılık Yönetimi (Dependencies)

Sistemin çalışması için gerekli olan paketler `pubspec.yaml` dosyasında tanımlanmıştır. Zeytin'in gücü, doğru paketlerin doğru amaçla kullanılmasından gelir:

* **shelf & shelf_router:** Sunucunun HTTP isteklerini dinlemesi ve yönlendirmesi için kullanılır. Web sunucusunun iskeletidir.
* **shelf_web_socket:** Gerçek zamanlı veri akışı ve "Watch" mekanizması için soket bağlantılarını yönetir.
* **encrypt:** `ZeytinTokener` sınıfının kullandığı AES şifreleme algoritmalarını sağlar.
* **dart_jsonwebtoken:** LiveKit ile güvenli iletişim kurmak için JWT tokenlarını oluşturur.
* **dio:** Sunucunun, kendi içindeki veya dış dünyadaki diğer servislere HTTP istekleri atmasını sağlar.

Kurulum tamamlandıktan sonra, sunucuyu yönetmek için `server/runner.dart` aracını kullanmaya hazırsınız demektir.


# 3. Depolama Motoru

Zeytin'i diğer sunucu çözümlerinden ayıran en temel özellik, kendine ait bir veritabanı motoruna sahip olmasıdır. Bu motor, veriyi işletim sisteminin dosya sistemi üzerinde, özel bir ikili formatta ve yüksek performanslı izolasyon teknikleri kullanarak yönetir.

Sistemin `lib/logic/engine.dart` dosyasında bulunan bu yapı, dört ana mekanizma üzerine kuruludur: **Binary Encoder**, **Persistent Index**, **Isolate Mimarisi** ve **Compaction**.

## 3.1. İkili Veri Formatı

Zeytin, verileri diske yazarken JSON veya XML gibi metin tabanlı formatlar kullanmaz. Bunun yerine, disk alanından tasarruf etmek ve okuma-yazma hızını artırmak için `BinaryEncoder` sınıfı tarafından yönetilen özel bir protokol kullanır.

Veriler `ByteData` ve `Uint8List` kullanılarak işlenir ve Little Endian düzeninde paketlenir. Her veri bloğu, veri bütünlüğünü sağlamak adına `0xDB` yani Magic Byte ile başlar. Bu sihirli bayt, motorun veri bozulmalarını algılamasına yardımcı olur.

Diskteki bir veri bloğunun yapısı şöyledir:

| MAGIC (1 Byte) | BOX_ID_LEN (4 Byte) | BOX_ID (N Byte) | TAG_LEN (4 Byte) | TAG (N Byte) | DATA_LEN (4 Byte) | DATA (N Byte) |
|----------------|---------------------|-----------------|------------------|--------------|-------------------|---------------|
| 0xDB           | 0x00000008          | "settings"      | 0x00000005       | "theme"      | 0x0000000E        | {Binary Map}  |


Bu yapı sayesinde motor, diskteki rastgele bir konuma gittiğinde verinin nerede başladığını, hangi kutuya ve etikete ait olduğunu ve verinin nerede bittiğini hatasız bir şekilde anlayabilir.

Desteklenen veri tipleri ve sistemdeki kimlik numaraları şunlardır:
* `NULL` (0)
* `BOOL` (1)
* `INT` (2) - 64 bit tamsayı
* `DOUBLE` (3) - 64 bit kayar noktalı sayı
* `STRING` (4) - UTF8 kodlanmış metin
* `LIST` (5) - Dinamik listeler
* `MAP` (6) - Anahtar-değer haritaları

## 3.2. Kalıcı İndeksleme

Veritabanı motorlarının en büyük problemi, veri büyüdükçe arama süresinin uzamasıdır. Zeytin, bu sorunu `PersistentIndex` sınıfı ile çözer.

Sistem, veri dosyası (`.dat`) ile eşzamanlı olarak bir indeks dosyası (`.idx`) tutar. Bu indeks dosyası, verinin kendisini değil, verinin disk üzerindeki **adresini** (offset) ve **büyüklüğünü** (length) saklar.

Sunucu ayağa kalktığında veya bir Truck yüklendiğinde, bu indeks dosyası tamamen belleğe yani RAM'e alınır. Böylece bir veriye ulaşmak istediğinizde sistem diski taramaz; doğrudan bellekteki haritadan verinin koordinatlarını alır ve diskten sadece o noktayı okur. Bu da veri boyutu gigabaytlarca olsa bile erişim süresinin milisaniyeler seviyesinde kalmasını sağlar.

Örnek bir indeks haritası bellekte şöyle görünür:

```text
Box: "users"
  └── Tag: "user_123" -> [Offset: 1024, Length: 256]
  └── Tag: "user_456" -> [Offset: 1280, Length: 512]
```

## 3.3. Isolate ve Proxy Mimarisi

Dart dili doğası gereği tek iş parçacıklı bir yapıya sahiptir. Ağır disk işlemleri (I/O) ana iş parçacığını bloklayabilir ve sunucunun gelen diğer isteklere cevap verememesine neden olabilir. Zeytin, bu darboğazı aşmak için **Actor Model** benzeri bir yapı kullanır.

Her bir kullanıcı veritabanı yani Truck, ana sunucudan bağımsız bir **Isolate** içinde çalışır. Isolate'ler hafızayı paylaşmazlar, birbirleriyle mesajlaşarak haberleşirler.

1.  **TruckProxy:** Ana sunucu tarafında çalışır. İstekleri karşılar ve bir mesaj kuyruğuna dönüştürür.
2.  **SendPort / ReceivePort:** Ana sunucu ile izole motor arasındaki iletişim köprüsüdür.
3.  **TruckIsolate:** Arka planda çalışan, belleği ve işlem sırası tamamen ayrılmış motordur.

Bu mimari sayesinde, bir kullanıcının veritabanında yaptığı çok ağır bir toplu yazma işlemi, sunucudaki diğer kullanıcıların işlemlerini veya anlık video görüşmelerini asla yavaşlatmaz.

## 3.4. Append-Only Yazma ve Sıkıştırma

Zeytin motoru, veri güvenliğini sağlamak için **Append-Only** yani "Sadece Ekleme" mantığıyla çalışır. Bir veriyi güncellediğinizde veya sildiğinizde, eski veri diskten hemen silinmez. Bunun yerine dosyanın en sonuna verinin yeni hali veya silindiğine dair işaret eklenir ve indeks güncellenir.

Bu yöntem veri kaybı riskini minimize eder ancak zamanla veri dosyasının şişmesine ve içinde "ölü" verilerin birikmesine neden olur.

Bunu engellemek için `Truck` sınıfı içinde otomatik bir **Compaction** mekanizması bulunur:
1.  Her 500 yazma işleminden sonra sistem tetiklenir.
2.  Motor, geçici bir dosya (`_temp.dat`) oluşturur.
3.  Sadece **aktif ve geçerli** olan, yani indekste son hali kayıtlı olan verileri bu yeni dosyaya transfer eder.
4.  Eski ve gereksiz veriler geride bırakılır.
5.  İşlem bittiğinde eski dosya silinir ve yeni dosya asıl veri dosyası olarak isimlendirilir.

Bu süreç arka planda ve izole bir şekilde gerçekleştiği için sistem kesintiye uğramadan kendi kendini temizler ve optimize eder.


# 4. Güvenlik ve Kimlik Doğrulama

Zeytin, güvenlik konusunu uygulamanın en dış katmanından verinin en derin saklanma biçimine kadar ele alan iki ana mekanizma üzerine kurmuştur: **Gatekeeper** ve **Tokener**.

Bu bölümde, sunucunuzu kötü niyetli saldırılardan koruyan Gatekeeper yapısını ve verilerinizin ağ üzerinde şifreli taşınmasını sağlayan Tokener mekanizmasını inceleyeceğiz.

## 4.1. Gatekeeper: İlk Savunma Hattı

Gatekeeper, sunucunuza gelen her isteği karşılayan ilk bileşendir. Bir gece kulübündeki koruma görevlisi gibi çalışır; kimin girip kimin giremeyeceğine, ne sıklıkla istek atabileceğine karar verir.

`lib/logic/gatekeeper.dart` dosyasında bulunan bu yapı, aşağıdaki tehditlere karşı aktif koruma sağlar:

### DoS ve DDoS Koruması (Sleep Mode)
Zeytin, küresel bir sayaç kullanarak sunucuya gelen toplam istek sayısını anlık olarak takip eder. Eğer `globalDosThreshold` (varsayılan: 50.000 istek) aşılırsa, sistem kendini otomatik olarak **Uyku Moduna (Sleep Mode)** alır.

* **Tepki:** Sunucu 503 Service Unavailable hatası döndürür.
* **Mesaj:** "Be quiet! I'm trying to sleep here."
* **Süre:** Sistem belirtilen süre boyunca (varsayılan: 5 dakika) tüm yeni istekleri reddeder ve işlemciyi soğumaya bırakır.

### Akıllı Hız Sınırlama (Rate Limiting)
Her IP adresi için ayrı bir aktivite kaydı tutulur. Gatekeeper, IP bazlı iki farklı hız sınırı uygular:

1.  **Genel İstek Sınırı:** Bir IP adresi, 5 saniye içinde `generalIpRateLimit5Sec` (varsayılan: 100) değerinden fazla istek gönderirse geçici olarak engellenir ve 429 Too Many Requests hatası alır.
2.  **Token Oluşturma Sınırı:** Giriş yapma ve token alma uç noktası (`/token/create`), kaba kuvvet (brute-force) saldırılarına karşı daha sıkı korunur. Bu uç noktaya saniyede sadece 1 kez istek atılabilir.

### IP Yönetimi (Blacklist & Whitelist)
`config.dart` dosyası üzerinden statik IP yönetimi yapabilirsiniz:
* **Blacklist:** Buraya eklenen IP adresleri, sunucuya hiçbir koşulda erişemez.
* **Whitelist:** Buraya eklenen IP adresleri (örneğin yerel ağ veya yönetici IP'si), hız sınırlarına takılmadan işlem yapabilir.

---

## 4.2. Token Yönetimi ve Oturumlar

Zeytin, durumsuz (stateless) bir REST API gibi davranmak yerine, süreli ve bellekte tutulan oturum tokenları kullanır.

### Token Yaşam Döngüsü
Bir kullanıcı `/token/create` adresine e-posta ve şifresiyle istek attığında, sistem bu bilgileri doğrular ve bellekte geçici bir UUID (Benzersiz Kimlik) oluşturur.

* **Ömür:** Tokenlar oluşturulduğu andan itibaren sadece **2 dakika (120 saniye)** geçerlidir.
* **Güvenlik:** Bu kadar kısa ömürlü olması, token'ın çalınması durumunda saldırganın işlem yapabilmesi için çok kısıtlı bir zamana sahip olmasını sağlar.
* **Yenileme:** İstemci tarafı, her 2 dakikada bir veya işlem yapmadan hemen önce yeni bir token talep etmelidir.

### Çoklu Hesap Kısıtlaması
Gatekeeper, aynı IP adresinden açılabilecek Truck (hesap) sayısını sınırlar. Varsayılan olarak bir IP adresi en fazla 20 farklı hesap oluşturabilir. Bu sınır aşılırsa o IP adresi otomatik olarak yasaklanır.

---

## 4.3. Tokener: Uçtan Uca Şifreleme

Zeytin üzerindeki kritik veri işlemleri (CRUD operasyonları ve WebSocket akışları), veriyi düz metin (JSON) olarak taşımaz. Bunun yerine **AES-CBC** algoritması kullanılarak şifrelenmiş paketler halinde taşır. Bu işlemi yöneten sınıf `ZeytinTokener`dır.

### Şifreleme Mantığı
Her kullanıcının şifreleme anahtarı, kendi giriş şifresinden türetilir. Bu, veritabanı yöneticisinin bile kullanıcı şifresini bilmeden verilerin içeriğini ağ trafiğini dinleyerek çözemeyeceği anlamına gelir.

**Veri Paketi Yapısı:**
Şifreli veri, İnitialization Vector (IV) ve Şifreli Metin (Ciphertext) olmak üzere iki parçadan oluşur ve aralarında iki nokta üst üste (`:`) bulunur.

Format: `IV_BASE64:CIPHERTEXT_BASE64`

### Örnek İstek ve Yanıt

Bir veriyi okumak için `/data/get` uç noktasına istek attığınızı düşünelim.

**İstemci İsteği (Client Request):**
İstemci, sunucuya `box` ve `tag` bilgisini açık değil, şifreli gönderir.
```json
{
  "token": "a1b2c3d4-...",
  "data": "r5T8...IV_BASE64...:e9K1...CIPHERTEXT..." 
  // "data" parametresi şifrelenmiş bir JSON nesnesidir: {"box": "settings", "tag": "theme"}
}
```

**Sunucu Yanıtı (Server Response):**
Sunucu veriyi bulur, okur ve yine şifreli olarak geri döner.
```json
{
  "isSuccess": true,
  "message": "Oki doki!",
  "data": "m7Z2...IV_BASE64...:p4L9...CIPHERTEXT..."
  // Şifresi çözüldüğünde: {"mode": "dark", "fontSize": 14}
}
```

### İstemci Tarafı Entegrasyonu
Zeytin ile konuşacak bir istemci uygulaması geliştiriyorsanız, `ZeytinTokener` sınıfındaki mantığı kendi dilinize uyarlamanız gerekir.

1.  **Anahtar Türetme:** Kullanıcının şifresini SHA-256 ile hashleyin. Çıkan bayt dizisi sizin AES anahtarınızdır.
2.  **Şifreleme:** Göndereceğiniz JSON verisini, rastgele üretilmiş 16 baytlık bir IV kullanarak AES-CBC modunda şifreleyin. Sonuç olarak `IV:ŞifreliVeri` stringini oluşturun.
3.  **Çözme:** Sunucudan gelen yanıtı `:` karakterinden ikiye bölün. İlk kısım IV, ikinci kısım şifreli veridir. Aynı anahtarı kullanarak veriyi çözün.

Bu yapı sayesinde, veri veritabanında binary olarak, ağ üzerinde ise şifreli olarak durur. Sadece geçerli oturuma sahip ve şifreyi bilen istemci veriyi anlamlı hale getirebilir.



# 5. API Referansı

Zeytin, veri güvenliğini en üst düzeyde tutmak için çoğu uç noktasında standart JSON yerine şifrelenmiş veri paketleri ile iletişim kurar. Bu nedenle API'yi kullanmadan önce "Şifreli Veri (Encrypted Data)" kavramını anlamak hayati önem taşır.

Aksi belirtilmediği sürece, **CRUD**, **Call** ve **Watch** altındaki tüm isteklerde `data` parametresi, kullanıcının şifresiyle türetilmiş AES anahtarı kullanılarak şifrelenmiş bir JSON dizesi olmalıdır.

---

## 5.1. Hesap ve Oturum Yönetimi

Bu uç noktalar veritabanı motoruna giriş kapısıdır. Buradaki veriler şifrelenmeden, açık JSON formatında gönderilir.

### Yeni Hesap (Truck) Oluşturma
Sistemde yeni bir kullanıcı alanı (Truck) oluşturur.

* **Uç Nokta:** `POST /truck/create`
* **Gövde (Body):**
    ```json
    {
      "email": "ornek@mail.com",
      "password": "guclu_bir_sifre"
    }
    ```
* **Yanıt:** Başarılı olursa oluşturulan Truck ID'sini döner.

### Hesap ID Sorgulama
E-posta ve şifre doğrulaması yaparak kullanıcının Truck ID'sini getirir.

* **Uç Nokta:** `POST /truck/id`
* **Gövde:** E-posta ve şifre (yukarıdakiyle aynı).

### Token Oluşturma (Oturum Açma)
İşlem yapmak için gerekli olan geçici oturum anahtarını (Token) üretir. Bu token 2 dakika (120 saniye) geçerlidir.

* **Uç Nokta:** `POST /token/create`
* **Gövde:**
    ```json
    {
      "email": "ornek@mail.com",
      "password": "guclu_bir_sifre"
    }
    ```
* **Yanıt:** `{"token": "uuid-formatinda-token"}`

### Token Silme (Çıkış Yapma)
Aktif bir token'ı süresi dolmadan geçersiz kılar.

* **Uç Nokta:** `DELETE /token/delete`
* **Gövde:** E-posta ve şifre.

---

## 5.2. Veri İşlemleri (CRUD)

Bu bölümdeki tüm istekler iki parametre alır:
1.  `token`: `/token/create` adresinden alınan geçerli oturum anahtarı.
2.  `data`: İstenen işlemin parametrelerini içeren **şifrelenmiş** string.

> **Not:** Aşağıdaki örneklerde `data` içeriği, şifrelenmeden önceki (açık) haliyle gösterilmiştir. Gerçek istekte bu JSON, `ZeytinTokener` ile şifrelenip gönderilmelidir.

### Veri Ekleme / Güncelleme
Belirtilen kutuya (Box) ve etikete (Tag) veri yazar. Etiket varsa günceller, yoksa oluşturur.

* **Uç Nokta:** `POST /data/add`
* **Şifreli Veri İçeriği:**
    ```json
    {
      "box": "ayarlar",
      "tag": "tema",
      "value": { "mod": "koyu", "renk": "mavi" }
    }
    ```

### Toplu Veri Ekleme (Batch)
Tek seferde birden fazla veriyi tek bir kutuya yazar. Performans için tercih edilmelidir.

* **Uç Nokta:** `POST /data/addBatch`
* **Şifreli Veri İçeriği:**
    ```json
    {
      "box": "urunler",
      "entries": {
        "urun_1": { "ad": "Laptop", "fiyat": 5000 },
        "urun_2": { "ad": "Mouse", "fiyat": 100 }
      }
    }
    ```

### Veri Okuma (Tekil)
Belirli bir etiketteki veriyi getirir.

* **Uç Nokta:** `POST /data/get`
* **Şifreli Veri İçeriği:** `{ "box": "ayarlar", "tag": "tema" }`
* **Yanıt:** Şifrelenmiş veri döner. İstemci tarafında çözülmelidir.

### Kutu Okuma (Tümü)
Bir kutudaki tüm verileri getirir. Dikkatli kullanılmalıdır, büyük kutularda işlem uzun sürebilir.

* **Uç Nokta:** `POST /data/getBox`
* **Şifreli Veri İçeriği:** `{ "box": "urunler" }`

### Veri Silme
Belirli bir etiketi ve verisini siler.

* **Uç Nokta:** `POST /data/delete`
* **Şifreli Veri İçeriği:** `{ "box": "ayarlar", "tag": "tema" }`

### Kutu Silme
Bir kutuyu ve içindeki tüm verileri tamamen temizler.

* **Uç Nokta:** `POST /data/deleteBox`
* **Şifreli Veri İçeriği:** `{ "box": "gecmis_loglari" }`

### Varlık Kontrolleri
Verinin olup olmadığını kontrol eden hafif uç noktalardır. Verinin kendisini değil, sadece `true/false` bilgisini şifreli olarak dönerler.

* **Etiket Var mı?:** `POST /data/existsTag` -> `{ "box": "...", "tag": "..." }`
* **Kutu Var mı?:** `POST /data/existsBox` -> `{ "box": "..." }`
* **İçerik Kontrolü:** `POST /data/contains` -> `{ "box": "...", "tag": "..." }` (Verinin bellekte veya diskte fiziksel varlığını doğrular).

### Arama ve Filtreleme
* **Önek Araması (Search):** Bir alandaki (field) değerin belirli bir kelimeyle (prefix) başlayıp başlamadığını arar.
    * **Uç Nokta:** `POST /data/search`
    * **Şifreli Veri:** `{ "box": "kullanicilar", "field": "isim", "prefix": "Ahmet" }`

* **Tam Eşleşme (Filter):** Bir alandaki değerin tam olarak eşleştiği kayıtları getirir.
    * **Uç Nokta:** `POST /data/filter`
    * **Şifreli Veri:** `{ "box": "kullanicilar", "field": "yas", "value": 25 }`

---

## 5.3. Dosya Depolama (Storage)

Dosya yükleme işlemleri standart `multipart/form-data` formatında yapılır. Şifreleme kullanılmaz ancak Token zorunludur.

### Dosya Yükleme
* **Uç Nokta:** `POST /storage/upload`
* **Yöntem:** Multipart Form Data
* **Alanlar:**
    * `token`: Geçerli oturum anahtarı (String).
    * `file`: Yüklenecek dosya (Binary).
* **Kısıtlamalar:** `.exe`, `.php`, `.sh`, `.html` vb. çalıştırılabilir dosyalar güvenlik nedeniyle reddedilir.

### Dosya İndirme / Görüntüleme
Yüklenen dosyalar herkese açık (public) olarak sunulur.

* **Uç Nokta:** `GET /<truckId>/<dosyaAdi>`
* **Örnek:** `GET /a1b2-c3d4.../profil_resmi.jpg`

---

## 5.4. Canlı İzleme (Watch - WebSocket)

İstemcilerin, veritabanındaki değişiklikleri (ekleme, silme, güncelleme) anlık olarak dinlemesini sağlar.

* **Uç Nokta:** `ws://sunucu-adresi/data/watch/<token>/<boxId>`
* **Parametreler:** URL içinde geçerli `token` ve izlenmek istenen `boxId` belirtilmelidir.
* **Olay Yapısı:** Sunucudan gelen mesajlar şu formatta JSON içerir:
    ```json
    {
      "op": "PUT", // İşlem tipi: PUT, UPDATE, DELETE, BATCH
      "tag": "degisen_veri_etiketi",
      "data": "SİFRELİ_VERİ", // Şifreli yeni değer
      "entries": null // Sadece batch işleminde doludur
    }
    ```

---

## 5.5. Görüşme ve Yayın (Call - LiveKit)

Zeytin, LiveKit sunucusu ile entegre çalışarak sesli ve görüntülü görüşmeler için gerekli "Oda (Room)" yönetimini sağlar.

### Odaya Katılma (Token Alma)
Görüşme başlatmak veya var olan bir odaya katılmak için LiveKit erişim tokenı üretir.

* **Uç Nokta:** `POST /call/join`
* **Şifreli Veri İçeriği:**
    ```json
    {
      "roomName": "toplanti_odasi_1",
      "uid": "kullanici_123"
    }
    ```
* **Yanıt:** LiveKit sunucu adresi ve JWT tokenını şifreli olarak döner.

### Oda Durumu Kontrolü
Bir odada aktif görüşme olup olmadığını kontrol eder.

* **Uç Nokta:** `POST /call/check`
* **Şifreli Veri İçeriği:** `{ "roomName": "toplanti_odasi_1" }`
* **Yanıt:** `isActive` (boolean) değerini şifreli döner.

### Canlı Oda Takibi (Stream)
Bir odanın aktiflik durumunu WebSocket üzerinden sürekli takip eder.

* **Uç Nokta:** `ws://sunucu-adresi/call/stream/<token>?data=ŞİFRELİ_VERİ`
* **Parametreler:**
    * URL yolunda `token`.
    * Query parametresi olarak `data`: `{ "roomName": "..." }` (Şifreli).
* **Davranış:** Oda durumu değiştiğinde (birisi girdiğinde veya son kişi çıktığında) sunucu anlık bildirim gönderir.


# 6. Sunucu Yönetimi

Zeytin, sadece bir yazılım değil, yaşayan bir sistemdir. Bu sistemi yönetmek için karmaşık Linux komutlarıyla (kill, nohup, tail vb.) uğraşmanıza gerek kalmaması için **Runner** adında etkileşimli bir yönetim paneli geliştirdik.

`server/runner.dart` dosyası, sunucunuzun kokpitidir. Başlatma, durdurma, güncelleme ve log izleme gibi operasyonel işlerin tamamı buradan yapılır.

## Runner'ı Başlatma

Sunucunuza SSH ile bağlandığınızda, yönetim arayüzünü açmak için şu komutu girmeniz yeterlidir:

```bash
dart server/runner.dart
```

Karşınıza renkli ve numaralandırılmış bir menü çıkacaktır. Bu menüdeki seçeneklerin ne işe yaradığını ve arka planda neler yaptığını aşağıda detaylandırdık.

---

## 6.1. Çalıştırma Modları

Sistemi başlatmak için iki farklı seçenek sunulur. Hangi durumda hangisini kullanacağınızı bilmeniz önemlidir.

### 1. Start Test Mode (Geliştirme Modu)
Bu seçenek, sunucuyu o anki terminal penceresinde, derleme yapmadan anında başlatır.
* **Kullanım Alanı:** Kod üzerinde değişiklik yaptıysanız ve hızlıca test etmek istiyorsanız bunu kullanın.
* **Davranış:** Terminali kapattığınızda veya `CTRL+C` yaptığınızda sunucu da kapanır. Hataları ve çıktıları doğrudan ekrana basar.
* **LiveKit Kontrolü:** Başlamadan önce Docker konteynerinin çalışıp çalışmadığını kontrol eder, kapalıysa otomatik açar.

### 2. Start Live Mode (Canlı Mod)
Bu seçenek, sunucuyu gerçek bir üretim ortamına hazırlar.
* **Derleme (Compilation):** Dart kodunu makine diline çevirerek (`.exe` formatında) optimize edilmiş bir dosya oluşturur. Bu sayede sunucu çok daha hızlı çalışır ve daha az bellek tüketir.
* **Arka Plan Çalışması:** Sunucuyu `nohup` komutuyla arka plana atar. SSH bağlantınızı kessseniz bile sunucu çalışmaya devam eder.
* **Kayıtlar:** Tüm çıktıları `zeytin.log` dosyasına yazar.
* **PID Takibi:** Çalışan işlemin kimlik numarasını `server.pid` dosyasına kaydeder. Bu sayede sunucuyu daha sonra kolayca durdurabilirsiniz.

---

## 6.2. İzleme ve Kontrol

Sunucu çalışırken durumunu takip etmek veya müdahale etmek için bu seçenekleri kullanabilirsiniz.

### 3. Watch Logs (Logları İzle)
Arka planda (Live Mode) çalışan sunucunun neler yaptığını anlık olarak görmek içindir. `tail -f zeytin.log` komutunu çalıştırır. Ekrana akan yazıları durdurmak için `CTRL+C` yapabilirsiniz; bu işlem sunucuyu kapatmaz, sadece izleme ekranından çıkar.

### 4. Stop Server (Sunucuyu Durdur)
Çalışan Zeytin sunucusunu güvenli bir şekilde kapatır. Runner, önce `server.pid` dosyasına bakar ve ilgili işlemi sonlandırır. Eğer dosya yoksa veya silinmişse, sistemdeki tüm Zeytin süreçlerini zorla temizler.

---

## 6.3. Bakım ve Altyapı İşlemleri

Sistemin güncelliğini ve sağlığını korumak için gerekli araçlardır.

### 6. UPDATE SYSTEM (Sistemi Güncelle)
GitHub deposunda yeni bir güncelleme yayınlandığında bu seçeneği kullanın. Bu işlem sırasıyla şunları yapar:
1.  Mevcut `config.dart` dosyanızın yedeğini alır. (Ayarlarınız kaybolmaz)
2.  `git pull` komutuyla en yeni kodları sunucuya indirir.
3.  Yedeklediği yapılandırma dosyasını geri yükler.
4.  `dart pub get` ile yeni eklenen kütüphaneleri indirir.
5.  İşlem bitince sunucuyu yeniden başlatmanız gerekir.

### 7. Clear Database & Storage (Verileri Temizle)
Bu seçenek **tehlikelidir**. Sunucuyu durdurur ve `zeytin/` klasörü içindeki tüm kullanıcı verilerini, dosyaları ve indeksleri kalıcı olarak siler. Sıfırdan temiz bir başlangıç yapmak istediğinizde kullanın.

### 5. UNINSTALL SYSTEM (Sistemi Kaldır)
En tehlikeli seçenektir. Sunucuyu durdurur ve tüm proje klasörünü diskten siler. Geri dönüşü yoktur.

---

## 6.4. Nginx Yönetimi

Eğer kurulum aşamasında SSL ve Domain ayarlarını yapmadıysanız veya değiştirmek istiyorsanız bu menüyü kullanabilirsiniz.

### 8. Nginx & SSL Setup
`install.sh` dosyasını tekrar tetikler. Yeni bir domain tanımlamak veya SSL sertifikası almak için kullanılır.

### 9. Remove Nginx Config
Zeytin için oluşturulmuş Nginx ayar dosyalarını ve kısayollarını siler, ardından Nginx servisini yeniden başlatır. Sunucunuz artık dış dünyaya (80/443 portlarına) yanıt vermez, sadece yerel porttan (12852) çalışır.




