import 'dart:io';
import 'dart:convert';
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