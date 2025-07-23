import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'kegiatan.dart';

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
  
  // Method untuk menghitung lebar kolom yang dinamis
  Map<String, int> _hitungLebarKolom() {
    if (_daftarKegiatan.isEmpty) {
      return {
        'no': 4,
        'waktu': 11,
        'kegiatan': 12,
        'prioritas': 11,
        'deskripsi': 13
      };
    }
    
    // Lebar minimum untuk setiap kolom
    int lebarNo = max(4, _daftarKegiatan.length.toString().length + 2);
    int lebarWaktu = max(11, "Waktu".length + 2);
    int lebarKegiatan = max(12, "Kegiatan".length + 2);
    int lebarPrioritas = max(11, "Prioritas".length + 2);
    int lebarDeskripsi = max(13, "Deskripsi".length + 2);
    
    // Hitung lebar maksimum berdasarkan konten
    for (Kegiatan k in _daftarKegiatan) {
      lebarWaktu = max(lebarWaktu, k.formatWaktu.length + 2);
      lebarKegiatan = max(lebarKegiatan, k.nama.length + 2);
      lebarPrioritas = max(lebarPrioritas, k.formatPrioritas.length + 2);
      lebarDeskripsi = max(lebarDeskripsi, (k.deskripsi ?? "").length + 2);
    }
    
    return {
      'no': lebarNo,
      'waktu': lebarWaktu,
      'kegiatan': lebarKegiatan,
      'prioritas': lebarPrioritas,
      'deskripsi': lebarDeskripsi
    };
  }
  
  // Method untuk membuat separator tabel
  String _buatSeparator(Map<String, int> lebar) {
    String separator = "|";
    separator += "-" * lebar['no']! + "+";
    separator += "-" * lebar['waktu']! + "+";
    separator += "-" * lebar['kegiatan']! + "+";
    separator += "-" * lebar['prioritas']! + "+";
    separator += "-" * lebar['deskripsi']! + "|";
    return separator;
  }
  
  // Method untuk memformat baris tabel
  String _formatBaris(String no, String waktu, String kegiatan, String prioritas, String deskripsi, Map<String, int> lebar) {
    return "|${no.padLeft(lebar['no']! - 1)} |${waktu.padLeft(lebar['waktu']! - 1)} |${kegiatan.padLeft(lebar['kegiatan']! - 1)} |${prioritas.padLeft(lebar['prioritas']! - 1)} |${deskripsi.padLeft(lebar['deskripsi']! - 1)} |";
  }
  
  // Method untuk menampilkan agenda dalam bentuk tabel CLI dinamis
  void tampilkanAgenda() {
    if (_daftarKegiatan.isEmpty) {
      print("\n❌ Tidak ada kegiatan dalam agenda!");
      return;
    }
    
    urutkanKegiatan();
    
    // Hitung lebar kolom yang dinamis
    Map<String, int> lebarKolom = _hitungLebarKolom();
    
    // Hitung total lebar tabel
    int totalLebar = lebarKolom.values.reduce((a, b) => a + b) + 5; // +5 untuk separator
    
    print("\n" + "="*totalLebar);
    print("📅 AGENDA HARIAN PRIORITAS".padLeft((totalLebar + "📅 AGENDA HARIAN PRIORITAS".length) ~/ 2));
    print("="*totalLebar);
    
    // Header tabel
    print(_formatBaris("No", "Waktu", "Kegiatan", "Prioritas", "Deskripsi", lebarKolom));
    print(_buatSeparator(lebarKolom));
    
    // Isi tabel
    for (int i = 0; i < _daftarKegiatan.length; i++) {
      Kegiatan k = _daftarKegiatan[i];
      String no = (i + 1).toString();
      String waktu = k.formatWaktu;
      String nama = k.nama;
      String prioritas = k.formatPrioritas;
      String deskripsi = k.deskripsi ?? "";
      
      print(_formatBaris(no, waktu, nama, prioritas, deskripsi, lebarKolom));
    }
    
    print("="*totalLebar);
    print("Total kegiatan: ${_daftarKegiatan.length}");
  }
  
  // Method untuk menampilkan agenda dengan mode compact (jika terlalu lebar untuk terminal)
  void tampilkanAgendaCompact() {
    if (_daftarKegiatan.isEmpty) {
      print("\n❌ Tidak ada kegiatan dalam agenda!");
      return;
    }
    
    urutkanKegiatan();
    
    // Batasi lebar maksimum untuk mode compact
    const int maxLebarKegiatan = 20;
    const int maxLebarDeskripsi = 25;
    
    Map<String, int> lebarKolom = _hitungLebarKolom();
    
    // Batasi lebar jika terlalu panjang
    if (lebarKolom['kegiatan']! > maxLebarKegiatan) {
      lebarKolom['kegiatan'] = maxLebarKegiatan;
    }
    if (lebarKolom['deskripsi']! > maxLebarDeskripsi) {
      lebarKolom['deskripsi'] = maxLebarDeskripsi;
    }
    
    int totalLebar = lebarKolom.values.reduce((a, b) => a + b) + 5;
    
    print("\n" + "="*totalLebar);
    print("📅 AGENDA HARIAN PRIORITAS".padLeft((totalLebar + "📅 AGENDA HARIAN PRIORITAS".length) ~/ 2));
    print("="*totalLebar);
    
    // Header tabel
    print(_formatBaris("No", "Waktu", "Kegiatan", "Prioritas", "Deskripsi", lebarKolom));
    print(_buatSeparator(lebarKolom));
    
    // Isi tabel dengan pemotongan teks jika perlu
    for (int i = 0; i < _daftarKegiatan.length; i++) {
      Kegiatan k = _daftarKegiatan[i];
      String no = (i + 1).toString();
      String waktu = k.formatWaktu;
      String nama = k.nama.length > maxLebarKegiatan - 2 
          ? k.nama.substring(0, maxLebarKegiatan - 5) + "..." 
          : k.nama;
      String prioritas = k.formatPrioritas;
      String deskripsi = (k.deskripsi ?? "").length > maxLebarDeskripsi - 2
          ? (k.deskripsi ?? "").substring(0, maxLebarDeskripsi - 5) + "..."
          : (k.deskripsi ?? "");
      
      print(_formatBaris(no, waktu, nama, prioritas, deskripsi, lebarKolom));
    }
    
    print("="*totalLebar);
    print("Total kegiatan: ${_daftarKegiatan.length}");
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
  
  // Getter untuk mendapatkan jumlah kegiatan
  int get jumlahKegiatan => _daftarKegiatan.length;
}