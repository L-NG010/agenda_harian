import 'dart:io';
import 'dart:convert';

// Tingkat prioritas kegiatan
enum Prioritas { rendah, sedang, tinggi, mendesak }

class Kegiatan {
  String nama;
  String waktu;
  Prioritas prioritas;

  Kegiatan(this.nama, this.waktu, this.prioritas);

  // Konversi ke format JSON
  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'waktu': waktu,
      'prioritas': prioritas.toString().split('.').last,
    };
  }

  // Membuat Kegiatan dari JSON
  factory Kegiatan.fromJson(Map<String, dynamic> json) {
    return Kegiatan(
      json['nama'],
      json['waktu'],
      Prioritas.values.firstWhere(
          (p) => p.toString().split('.').last == json['prioritas']),
    );
  }
}

List<Kegiatan> daftarKegiatan = [];

// Menyimpan daftar kegiatan ke file
void simpanKeFile() {
  final file = File('agenda.json');
  final jsonData = jsonEncode(daftarKegiatan.map((k) => k.toJson()).toList());
  file.writeAsStringSync(jsonData);
}

// Memuat daftar kegiatan dari file
void muatDariFile() {
  final file = File('agenda.json');
  
  // Jika file tidak ada, tidak perlu memuat
  if (!file.existsSync()) {
    print("File agenda.json belum ada.");
    return;
  }

  try {
    final jsonString = file.readAsStringSync();
    
    // Jika file kosong, tidak perlu memuat
    if (jsonString.isEmpty) {
      print("File agenda.json kosong.");
      return;
    }

    // Decode JSON dan tambahkan ke daftar kegiatan
    final jsonData = jsonDecode(jsonString) as List;
    daftarKegiatan = jsonData.map((j) => Kegiatan.fromJson(j)).toList();
  } catch (e) {
    print("Gagal memuat agenda.json: $e");
  }
}

// Menampilkan menu utama
void tampilkanMenu() {
  print("\n=== MENU AGENDA ===");
  print("1. Tambah Kegiatan");
  print("2. Lihat Agenda");
  print("3. Hapus Kegiatan");
  print("0. Keluar");
  stdout.write("Pilih menu (0-3): ");
}

// Menambahkan kegiatan baru
void tambahKegiatan() {
  print("\n--- Tambah Kegiatan Baru ---");
  
  // Input nama kegiatan
  String nama;
  while (true) {
    stdout.write("Nama kegiatan: ");
    nama = stdin.readLineSync()?.trim() ?? '';
    
    if (nama.isNotEmpty) {
      break;
    }
    print("Nama tidak boleh kosong!");
  }

  // Input waktu kegiatan
  String waktu;
  while (true) {
    stdout.write("Waktu (format HH:MM): ");
    waktu = stdin.readLineSync()?.trim() ?? '';
    
    // Validasi format waktu
    if (RegExp(r'^(?:[01][0-9]|2[0-3]):[0-5][0-9]$').hasMatch(waktu)) {
      break;
    }
    print("Format waktu salah! Gunakan HH:MM (contoh: 14:30)");
  }

  // Input prioritas
  Prioritas prioritas;
  while (true) {
    print("\nPilih prioritas:");
    print("1. Rendah");
    print("2. Sedang");
    print("3. Tinggi");
    print("4. Mendesak");
    stdout.write("Pilihan (1-4): ");
    final pilihan = stdin.readLineSync()?.trim();
    
    switch (pilihan) {
      case '1':
        prioritas = Prioritas.rendah;
        break;
      case '2':
        prioritas = Prioritas.sedang;
        break;
      case '3':
        prioritas = Prioritas.tinggi;
        break;
      case '4':
        prioritas = Prioritas.mendesak;
        break;
      default:
        print("Pilihan tidak valid!");
        continue;
    }
    break;
  }

  // Tambahkan ke daftar dan simpan
  daftarKegiatan.add(Kegiatan(nama, waktu, prioritas));
  simpanKeFile();
  print("\nKegiatan berhasil ditambahkan!");
}

// Menampilkan daftar kegiatan
void lihatAgenda() {
  print("\n--- Daftar Kegiatan ---");
  
  if (daftarKegiatan.isEmpty) {
    print("Belum ada kegiatan.");
    return;
  }

  // Urutkan berdasarkan prioritas (mendesak pertama) dan waktu
  daftarKegiatan.sort((a, b) {
    if (a.prioritas != b.prioritas) {
      return b.prioritas.index.compareTo(a.prioritas.index);
    }
    return a.waktu.compareTo(b.waktu);
  });

  // Tampilkan dalam format tabel sederhana
  print("No. | Nama Kegiatan          | Waktu  | Prioritas");
  print("----|------------------------|--------|----------");
  for (int i = 0; i < daftarKegiatan.length; i++) {
    final kegiatan = daftarKegiatan[i];
    print("${(i + 1).toString().padRight(3)} | ${kegiatan.nama.padRight(22)} | ${kegiatan.waktu.padRight(6)} | ${kegiatan.prioritas.toString().split('.').last}");
  }
}

// Menghapus kegiatan
void hapusKegiatan() {
  print("\n--- Hapus Kegiatan ---");
  
  if (daftarKegiatan.isEmpty) {
    print("Belum ada kegiatan.");
    return;
  }

  // Tampilkan daftar untuk dipilih
  lihatAgenda();
  
  // Input nomor yang akan dihapus
  int? nomor;
  while (true) {
    stdout.write("\nMasukkan nomor kegiatan yang akan dihapus (0 untuk batal): ");
    final input = stdin.readLineSync()?.trim();
    nomor = int.tryParse(input ?? '');
    
    if (nomor == null || nomor < 0 || nomor > daftarKegiatan.length) {
      print("Nomor tidak valid!");
      continue;
    }
    
    if (nomor == 0) {
      print("Penghapusan dibatalkan.");
      return;
    }
    break;
  }

  // Hapus kegiatan dan simpan perubahan
  daftarKegiatan.removeAt(nomor - 1);
  simpanKeFile();
  print("Kegiatan berhasil dihapus!");
}

// Fungsi utama untuk menjalankan program
void main() {
  // Muat data dari file saat program dimulai
  muatDariFile();
  
  print("\n=== AGENDA HARIAN ===");
  print("Selamat datang di aplikasi Agenda Harian");
  
  String? pilihan;
  while (pilihan != "0") {
    tampilkanMenu();
    pilihan = stdin.readLineSync()?.trim();
    
    switch (pilihan) {
      case '1':
        tambahKegiatan();
        break;
      case '2':
        lihatAgenda();
        break;
      case '3':
        hapusKegiatan();
        break;
      case '0':
        print("Terima kasih, sampai jumpa!");
        break;
      default:
        print("Pilihan tidak valid!");
    }
    
    // Jeda sebelum kembali ke menu
    if (pilihan != "0") {
      print("\nTekan Enter untuk kembali ke menu...");
      stdin.readLineSync();
    }
  }
}