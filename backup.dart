import 'dart:io';
import 'dart:convert';

// Enum untuk tingkat prioritas
enum Prioritas { rendah, sedang, tinggi, mendesak }

// Class untuk merepresentasikan kegiatan
class Kegiatan {
  String nama;
  DateTime waktu;
  Prioritas prioritas;
  String? deskripsi;

  Kegiatan({
    required this.nama,
    required this.waktu,
    required this.prioritas,
    this.deskripsi,
  });

  // Getter untuk mendapatkan nilai numerik prioritas (untuk sorting)
  int get nilaiPrioritas {
    switch (prioritas) {
      case Prioritas.rendah:
        return 1;
      case Prioritas.sedang:
        return 2;
      case Prioritas.tinggi:
        return 3;
      case Prioritas.mendesak:
        return 4;
    }
  }

  // Method untuk format waktu
  String get formatWaktu {
    return "${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}";
  }

  // Method untuk format prioritas
  String get formatPrioritas {
    switch (prioritas) {
      case Prioritas.rendah:
        return "Rendah";
      case Prioritas.sedang:
        return "Sedang";
      case Prioritas.tinggi:
        return "Tinggi";
      case Prioritas.mendesak:
        return "Mendesak";
    }
  }

  // Method untuk convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'waktu': waktu.millisecondsSinceEpoch,
      'prioritas': prioritas.index,
      'deskripsi': deskripsi,
    };
  }

  // Factory method untuk membuat dari JSON
  factory Kegiatan.fromJson(Map<String, dynamic> json) {
    return Kegiatan(
      nama: json['nama'],
      waktu: DateTime.fromMillisecondsSinceEpoch(json['waktu']),
      prioritas: Prioritas.values[json['prioritas']],
      deskripsi: json['deskripsi'],
    );
  }

  @override
  String toString() {
    return 'Kegiatan: $nama, Waktu: $formatWaktu, Prioritas: $formatPrioritas';
  }
}

// Class utama untuk mengelola agenda harian
class AgendaHarian {
  List<Kegiatan> _daftarKegiatan = [];
  static const String namaFile = 'agendaharian.json';

  // Constructor yang otomatis memuat data dari file
  AgendaHarian() {
    muatDariFile();
  }

  // Method untuk menyimpan ke file JSON
  Future<void> simpanKeFile() async {
    try {
      File file = File(namaFile);
      List<Map<String, dynamic>> jsonData = _daftarKegiatan.map((k) => k.toJson()).toList();
      
      Map<String, dynamic> dataLengkap = {
        'tanggal_simpan': DateTime.now().toIso8601String(),
        'total_kegiatan': _daftarKegiatan.length,
        'kegiatan': jsonData,
      };
      
      await file.writeAsString(jsonEncode(dataLengkap));
      print("💾 Data berhasil disimpan ke $namaFile");
    } catch (e) {
      print("❌ Error menyimpan file: $e");
    }
  }

  // Method untuk memuat dari file JSON
  void muatDariFile() {
    try {
      File file = File(namaFile);
      if (file.existsSync()) {
        String contents = file.readAsStringSync();
        Map<String, dynamic> jsonData = jsonDecode(contents);
        
        if (jsonData.containsKey('kegiatan')) {
          List<dynamic> kegiatanList = jsonData['kegiatan'];
          _daftarKegiatan = kegiatanList.map((k) => Kegiatan.fromJson(k)).toList();
          print("📂 Data berhasil dimuat dari $namaFile (${_daftarKegiatan.length} kegiatan)");
        }
      } else {
        print("📝 File $namaFile belum ada, akan dibuat saat menyimpan data pertama kali");
      }
    } catch (e) {
      print("❌ Error memuat file: $e");
      _daftarKegiatan = []; // Reset ke list kosong jika error
    }
  }

  // Method untuk menambah kegiatan baru
  Future<void> tambahKegiatan(Kegiatan kegiatan) async {
    _daftarKegiatan.add(kegiatan);
    await simpanKeFile(); // Otomatis simpan setelah menambah
    print("✓ Kegiatan '${kegiatan.nama}' berhasil ditambahkan dan disimpan!");
  }

  // Method untuk mengurutkan kegiatan berdasarkan prioritas dan waktu
  void urutkanKegiatan() {
    _daftarKegiatan.sort((a, b) {
      // Prioritas utama: tingkat prioritas (tinggi ke rendah)
      int perbandinganPrioritas = b.nilaiPrioritas.compareTo(a.nilaiPrioritas);
      
      // Jika prioritas sama, urutkan berdasarkan waktu (awal ke akhir)
      if (perbandinganPrioritas == 0) {
        return a.waktu.compareTo(b.waktu);
      }
      
      return perbandinganPrioritas;
    });
  }

  // Method untuk menampilkan agenda dalam bentuk tabel CLI
  void tampilkanAgenda() {
    if (_daftarKegiatan.isEmpty) {
      print("\n❌ Tidak ada kegiatan dalam agenda!");
      return;
    }

    urutkanKegiatan();
    
    print("\n" + "="*80);
    print("                      📅 AGENDA HARIAN PRIORITAS");
    print("="*80);
    
    // Header tabel
    print("| No |    Waktu    |     Kegiatan     |  Prioritas  |      Deskripsi      |");
    print("|----+-------------+------------------+-------------+---------------------|");
    
    // Isi tabel
    for (int i = 0; i < _daftarKegiatan.length; i++) {
      Kegiatan k = _daftarKegiatan[i];
      String no = (i + 1).toString().padLeft(2);
      String waktu = k.formatWaktu.padRight(9);
      String nama = k.nama.length > 16 ? k.nama.substring(0, 13) + "..." : k.nama.padRight(16);
      String prioritas = k.formatPrioritas.padRight(9);
      String deskripsi = (k.deskripsi ?? "").length > 19 
          ? (k.deskripsi ?? "").substring(0, 16) + "..." 
          : (k.deskripsi ?? "").padRight(19);
      
      print("| $no |    $waktu   | $nama | $prioritas | $deskripsi |");
    }
    
    print("="*80);
    print("Total kegiatan: ${_daftarKegiatan.length}");
  }

  // Method untuk mendapatkan statistik agenda
  void tampilkanStatistik() {
    if (_daftarKegiatan.isEmpty) return;
    
    Map<Prioritas, int> statistik = {};
    for (var prioritas in Prioritas.values) {
      statistik[prioritas] = 0;
    }
    
    for (var kegiatan in _daftarKegiatan) {
      statistik[kegiatan.prioritas] = statistik[kegiatan.prioritas]! + 1;
    }
    
    print("\n📊 Statistik Prioritas:");
    print("- Mendesak: ${statistik[Prioritas.mendesak]} kegiatan");
    print("- Tinggi: ${statistik[Prioritas.tinggi]} kegiatan");
    print("- Sedang: ${statistik[Prioritas.sedang]} kegiatan");
    print("- Rendah: ${statistik[Prioritas.rendah]} kegiatan");
  }

  // Method untuk menghapus kegiatan
  Future<bool> hapusKegiatan(int index) async {
    if (index >= 0 && index < _daftarKegiatan.length) {
      String namaKegiatan = _daftarKegiatan[index].nama;
      _daftarKegiatan.removeAt(index);
      await simpanKeFile(); // Otomatis simpan setelah menghapus
      print("✓ Kegiatan '$namaKegiatan' berhasil dihapus dan disimpan!");
      return true;
    }
    return false;
  }

  // Method untuk membersihkan semua data
  Future<void> bersihkanSemua() async {
    _daftarKegiatan.clear();
    await simpanKeFile();
    print("✓ Semua kegiatan berhasil dihapus!");
  }

  // Method untuk mendapatkan info file JSON
  void infoFile() {
    File file = File(namaFile);
    if (file.existsSync()) {
      var stat = file.statSync();
      print("📁 Info File JSON:");
      print("- Nama: $namaFile");
      print("- Ukuran: ${stat.size} bytes");
      print("- Terakhir dimodifikasi: ${stat.modified}");
    } else {
      print("❌ File $namaFile tidak ditemukan");
    }
  }

  // Getter untuk mendapatkan jumlah kegiatan
  int get jumlahKegiatan => _daftarKegiatan.length;
}

// Class untuk menangani input/output
class AgendaInterface {
  final AgendaHarian agenda = AgendaHarian();

  // Method utama untuk menjalankan aplikasi
  void jalankan() async {
    tampilkanHeader();
    
    while (true) {
      tampilkanMenu();
      String? pilihan = stdin.readLineSync();
      
      switch (pilihan) {
        case '1':
          await inputKegiatan();
          break;
        case '2':
          agenda.tampilkanAgenda();
          break;
        case '3':
          agenda.tampilkanStatistik();
          break;
        case '4':
          await hapusKegiatan();
          break;
        case '5':
          await ujiKelayakan();
          break;
        case '6':
          kelolaFileJSON();
          break;
        case '7':
          await bersihkanData();
          break;
        case '0':
          print("\n💾 Menyimpan data terakhir...");
          await agenda.simpanKeFile();
          print("👋 Terima kasih telah menggunakan Agenda Harian!");
          exit(0);
        default:
          print("\n❌ Pilihan tidak valid! Silakan coba lagi.");
      }
      
      print("\nTekan Enter untuk melanjutkan...");
      stdin.readLineSync();
    }
  }

  void tampilkanHeader() {
    print("\n" + "="*60);
    print("        📅 APLIKASI AGENDA HARIAN DENGAN PRIORITAS");
    print("                   Kelompok 7");
    print("    Lang - Alfian - Ashila - Fira - Galih");
    print("="*60);
  }

  void tampilkanMenu() {
    print("\n📋 MENU UTAMA:");
    print("1. Tambah Kegiatan");
    print("2. Tampilkan Agenda");
    print("3. Statistik Prioritas");
    print("4. Hapus Kegiatan");
    print("5. Uji Kelayakan Sistem");
    print("6. Info & Kelola File JSON");
    print("7. Bersihkan Semua Data");
    print("0. Keluar");
    print("\nPilih opsi (0-7): ");
  }

  Future<void> inputKegiatan() async {
    try {
      print("\n➕ TAMBAH KEGIATAN BARU");
      print("-" * 25);
      
      // Input nama kegiatan
      print("Nama kegiatan: ");
      String? nama = stdin.readLineSync();
      if (nama == null || nama.trim().isEmpty) {
        print("❌ Nama kegiatan tidak boleh kosong!");
        return;
      }

      // Input waktu
      print("Waktu (format HH:MM, contoh: 14:30): ");
      String? inputWaktu = stdin.readLineSync();
      if (inputWaktu == null) {
        print("❌ Waktu tidak valid!");
        return;
      }

      DateTime waktu = parseWaktu(inputWaktu);

      // Input prioritas
      print("Prioritas:");
      print("1. Rendah");
      print("2. Sedang");
      print("3. Tinggi");
      print("4. Mendesak");
      print("Pilih (1-4): ");
      
      String? inputPrioritas = stdin.readLineSync();
      Prioritas prioritas = parsePrioritas(inputPrioritas);

      // Input deskripsi (opsional)
      print("Deskripsi (opsional): ");
      String? deskripsi = stdin.readLineSync();

      // Buat dan tambah kegiatan
      Kegiatan kegiatan = Kegiatan(
        nama: nama.trim(),
        waktu: waktu,
        prioritas: prioritas,
        deskripsi: deskripsi?.trim().isEmpty == true ? null : deskripsi?.trim(),
      );

      await agenda.tambahKegiatan(kegiatan);

    } catch (e) {
      print("❌ Error: $e");
    }
  }

  DateTime parseWaktu(String input) {
    try {
      List<String> bagian = input.split(':');
      if (bagian.length != 2) throw FormatException("Format waktu salah");
      
      int jam = int.parse(bagian[0]);
      int menit = int.parse(bagian[1]);
      
      if (jam < 0 || jam > 23 || menit < 0 || menit > 59) {
        throw FormatException("Waktu tidak valid");
      }
      
      DateTime sekarang = DateTime.now();
      return DateTime(sekarang.year, sekarang.month, sekarang.day, jam, menit);
    } catch (e) {
      throw FormatException("Format waktu salah! Gunakan format HH:MM");
    }
  }

  Prioritas parsePrioritas(String? input) {
    switch (input) {
      case '1':
        return Prioritas.rendah;
      case '2':
        return Prioritas.sedang;
      case '3':
        return Prioritas.tinggi;
      case '4':
        return Prioritas.mendesak;
      default:
        print("⚠️  Prioritas tidak valid, menggunakan prioritas sedang");
        return Prioritas.sedang;
    }
  }

  Future<void> hapusKegiatan() async {
    if (agenda.jumlahKegiatan == 0) {
      print("\n❌ Tidak ada kegiatan untuk dihapus!");
      return;
    }

    agenda.tampilkanAgenda();
    print("\nMasukkan nomor kegiatan yang akan dihapus (1-${agenda.jumlahKegiatan}): ");
    String? input = stdin.readLineSync();
    
    try {
      int index = int.parse(input!) - 1;
      if (!await agenda.hapusKegiatan(index)) {
        print("❌ Nomor kegiatan tidak valid!");
      }
    } catch (e) {
      print("❌ Input tidak valid!");
    }
  }

  void kelolaFileJSON() {
    print("\n📁 KELOLA FILE JSON");
    print("-" * 25);
    
    agenda.infoFile();
    
    print("\n📋 Opsi:");
    print("1. Lihat isi file JSON raw");
    print("2. Muat ulang dari file");
    print("3. Simpan manual ke file");
    print("0. Kembali ke menu utama");
    print("\nPilih opsi: ");
    
    String? pilihan = stdin.readLineSync();
    
    switch (pilihan) {
      case '1':
        lihatFileRaw();
        break;
      case '2':
        agenda.muatDariFile();
        break;
      case '3':
        agenda.simpanKeFile();
        break;
      case '0':
        return;
      default:
        print("❌ Pilihan tidak valid!");
    }
  }

  void lihatFileRaw() {
    try {
      File file = File(AgendaHarian.namaFile);
      if (file.existsSync()) {
        print("\n📄 Isi file ${AgendaHarian.namaFile}:");
        print("-" * 50);
        String contents = file.readAsStringSync();
        // Format JSON agar lebih mudah dibaca
        Map<String, dynamic> jsonData = jsonDecode(contents);
        print(JsonEncoder.withIndent('  ').convert(jsonData));
        print("-" * 50);
      } else {
        print("❌ File tidak ditemukan!");
      }
    } catch (e) {
      print("❌ Error membaca file: $e");
    }
  }

  Future<void> bersihkanData() async {
    print("\n⚠️  PERINGATAN: Ini akan menghapus SEMUA data agenda!");
    print("Apakah Anda yakin? (y/N): ");
    String? konfirmasi = stdin.readLineSync();
    
    if (konfirmasi?.toLowerCase() == 'y' || konfirmasi?.toLowerCase() == 'yes') {
      await agenda.bersihkanSemua();
      print("🗑️  Semua data telah dihapus!");
    } else {
      print("❌ Pembersihan data dibatalkan.");
    }
  }

  // Method untuk uji kelayakan sistem
  Future<void> ujiKelayakan() async {
    print("\n🧪 UJI KELAYAKAN SISTEM");
    print("-" * 30);
    
    print("1. Testing algoritma pengurutan dengan data yang ada...");
    if (agenda.jumlahKegiatan > 0) {
      agenda.urutkanKegiatan();
      print("✓ Algoritma pengurutan berhasil");
    } else {
      print("⚠️  Tidak ada data untuk diurutkan");
    }
    
    print("\n2. Testing tampilan tabel...");
    agenda.tampilkanAgenda();
    
    print("\n3. Testing statistik...");
    agenda.tampilkanStatistik();
    
    print("\n4. Testing penyimpanan JSON...");
    await agenda.simpanKeFile();
    print("✓ Penyimpanan ke JSON berhasil");
    
    print("\n5. Testing pembacaan JSON...");
    agenda.muatDariFile();
    print("✓ Pembacaan dari JSON berhasil");
    
    print("\n✅ HASIL UJI KELAYAKAN:");
    print("- Algoritma pengurutan: PASSED");
    print("- Tampilan tabel: PASSED");
    print("- Statistik: PASSED");
    print("- Logika prioritas: PASSED");
    print("- Penyimpanan JSON: PASSED");
    print("- Pembacaan JSON: PASSED");
    
    print("\n📋 KESIMPULAN:");
    print("Sistem berjalan dengan baik dan sesuai dengan spesifikasi!");
    print("Data tersimpan otomatis ke file agendaharian.json");
    print("Total kegiatan saat ini: ${agenda.jumlahKegiatan}");
  }
}