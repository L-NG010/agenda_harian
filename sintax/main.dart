import 'dart:io';
import 'dart:convert';

enum TingkatPrioritas { rendah, sedang, tinggi, mendesak }

class Kegiatan {
  String nama;
  String waktu;
  TingkatPrioritas prioritas;

  Kegiatan(this.nama, this.waktu, this.prioritas);

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'waktu': waktu,
        'prioritas': prioritas.toString().split('.').last,
      };

  factory Kegiatan.fromJson(Map<String, dynamic> json) => Kegiatan(
        json['nama'],
        json['waktu'],
        TingkatPrioritas.values.firstWhere((e) => e.toString().split('.').last == json['prioritas']),
      );
}

List<Kegiatan> daftarKegiatan = [];

void simpanKeJson() {
  File('agenda.json').writeAsStringSync(jsonEncode(daftarKegiatan.map((k) => k.toJson()).toList()));
}

void muatDariJson() {
  final file = File('agenda.json');
  daftarKegiatan.clear();
  if (!file.existsSync()) {
    print("ℹ️ File agenda.json belum ada.");
    return;
  }
  try {
    final jsonString = file.readAsStringSync();
    if (jsonString.isEmpty) {
      print("ℹ️ File agenda.json kosong.");
      return;
    }
    daftarKegiatan = (jsonDecode(jsonString) as List).map((j) => Kegiatan.fromJson(j)).toList();
  } catch (e) {
    print("⚠️ Gagal memuat agenda.json: $e.");
  }
}

void tampilkanMenu() {
  print("\n=== MENU ===");
  print("1. Tambah");
  print("2. Lihat");
  print("3. Hapus");
  print("0. Keluar");
  print("\nPilih (0-3): ");
}

void tambahKegiatan() {
  print("\n+++ Tambah Kegiatan +++");
  stdout.write("Nama: ");
  String? nama = stdin.readLineSync()?.trim();
  if (nama == null || nama.isEmpty) {
    print("❌ Nama wajib diisi!");
    return;
  }

  String? waktu;
  while (true) {
    stdout.write("Waktu (HH:MM): ");
    waktu = stdin.readLineSync()?.trim();
    if (waktu == null || waktu.isEmpty) {
      print("❌ Waktu wajib diisi!");
      continue;
    }
    if (RegExp(r'^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(waktu)) break;
    print("❌ Format waktu salah! Gunakan HH:MM.");
  }

  TingkatPrioritas prioritas = TingkatPrioritas.sedang;
  while (true) {
    print("\nPrioritas:");
    print("1. Rendah 🟢");
    print("2. Sedang 🔵");
    print("3. Tinggi 🟠");
    print("4. Mendesak 🔴");
    stdout.write("Pilih (1-4): ");
    String? input = stdin.readLineSync()?.trim();
    if (["1", "2", "3", "4"].contains(input)) {
      prioritas = [
        TingkatPrioritas.rendah,
        TingkatPrioritas.sedang,
        TingkatPrioritas.tinggi,
        TingkatPrioritas.mendesak
      ][int.parse(input!) - 1];
      break;
    }
    print("❌ Pilih 1-4!");
  }

  daftarKegiatan.add(Kegiatan(nama, waktu, prioritas));
  simpanKeJson();
  print("\n✅ Kegiatan ditambahkan!");
}

void lihatAgenda() {
  print("\n=== Daftar Agenda ===");
  if (daftarKegiatan.isEmpty) {
    print("Belum ada kegiatan.");
    return;
  }

  // Urutkan: mendesak > tinggi > sedang > rendah, lalu waktu lebih awal
  final sortedKegiatan = daftarKegiatan.toList()
    ..sort((a, b) {
      int prioritasA = TingkatPrioritas.values.indexOf(a.prioritas);
      int prioritasB = TingkatPrioritas.values.indexOf(b.prioritas);
      if (prioritasA != prioritasB) return prioritasB.compareTo(prioritasA);
      return a.waktu.compareTo(b.waktu);
    });

  // Hitung lebar kolom
  int maxNo = sortedKegiatan.length.toString().length;
  int maxNama = "Nama".length;
  int maxWaktu = "Waktu".length;
  int maxPrioritas = "Prioritas".length;
  for (var keg in sortedKegiatan) {
    maxNama = maxNama > keg.nama.length ? maxNama : keg.nama.length;
    maxWaktu = maxWaktu > keg.waktu.length ? maxWaktu : keg.waktu.length;
    maxPrioritas = maxPrioritas > keg.prioritas.toString().split('.').last.length ? maxPrioritas : keg.prioritas.toString().split('.').last.length;
  }

  // Cetak tabel
  print("| ${"No".padRight(maxNo)} | ${"Nama".padRight(maxNama)} | ${"Waktu".padRight(maxWaktu)} | ${"Prioritas".padRight(maxPrioritas)} |");
  print("|${"-" * maxNo}-|${"-" * maxNama}-|${"-" * maxWaktu}-|${"-" * maxPrioritas}-|");
  for (int i = 0; i < sortedKegiatan.length; i++) {
    var keg = sortedKegiatan[i];
    print("| ${(i + 1).toString().padRight(maxNo)} | ${keg.nama.padRight(maxNama)} | ${keg.waktu.padRight(maxWaktu)} | ${keg.prioritas.toString().split('.').last.padRight(maxPrioritas)} |");
  }
  print("|${"-" * maxNo}-|${"-" * maxNama}-|${"-" * maxWaktu}-|${"-" * maxPrioritas}-|");
}

void hapusKegiatan() {
  print("\n--- Hapus Kegiatan ---");
  if (daftarKegiatan.isEmpty) {
    print("Belum ada kegiatan.");
    return;
  }

  // Urutkan untuk ditampilkan
  final sortedKegiatan = daftarKegiatan.toList()
    ..sort((a, b) {
      int prioritasA = TingkatPrioritas.values.indexOf(a.prioritas);
      int prioritasB = TingkatPrioritas.values.indexOf(b.prioritas);
      if (prioritasA != prioritasB) return prioritasB.compareTo(prioritasA);
      return a.waktu.compareTo(b.waktu);
    });

  // Tampilkan tabel
  int maxNo = sortedKegiatan.length.toString().length;
  int maxNama = "Nama".length;
  int maxWaktu = "Waktu".length;
  int maxPrioritas = "Prioritas".length;
  for (var keg in sortedKegiatan) {
    maxNama = maxNama > keg.nama.length ? maxNama : keg.nama.length;
    maxWaktu = maxWaktu > keg.waktu.length ? maxWaktu : keg.waktu.length;
    maxPrioritas = maxPrioritas > keg.prioritas.toString().split('.').last.length ? maxPrioritas : keg.prioritas.toString().split('.').last.length;
  }

  print("| ${"No".padRight(maxNo)} | ${"Nama".padRight(maxNama)} | ${"Waktu".padRight(maxWaktu)} | ${"Prioritas".padRight(maxPrioritas)} |");
  print("|${"-" * maxNo}-|${"-" * maxNama}-|${"-" * maxWaktu}-|${"-" * maxPrioritas}-|");
  for (int i = 0; i < sortedKegiatan.length; i++) {
    var keg = sortedKegiatan[i];
    print("| ${(i + 1).toString().padRight(maxNo)} | ${keg.nama.padRight(maxNama)} | ${keg.waktu.padRight(maxWaktu)} | ${keg.prioritas.toString().split('.').last.padRight(maxPrioritas)} |");
  }
  print("|${"-" * maxNo}-|${"-" * maxNama}-|${"-" * maxWaktu}-|${"-" * maxPrioritas}-|");

  // Hapus berdasarkan nomor di tabel
  stdout.write("Pilih nomor untuk dihapus (0 untuk batal): ");
  int? index = int.tryParse(stdin.readLineSync()?.trim() ?? "");
  if (index == null || index < 0 || index > sortedKegiatan.length) {
    print("❌ Pilihan salah!");
    return;
  }
  if (index == 0) {
    print("Batal.");
    return;
  }
  // Hapus kegiatan dari daftarKegiatan yang sesuai dengan sortedKegiatan[index - 1]
  daftarKegiatan.remove(sortedKegiatan[index - 1]);
  simpanKeJson();
  print("✅ Kegiatan dihapus!");
}

void jalankan() {
  String? pilihan;
  while (pilihan != "0") {
    tampilkanMenu();
    pilihan = stdin.readLineSync()?.trim();
    switch (pilihan) {
      case "1":
        tambahKegiatan();
        break;
      case "2":
        lihatAgenda();
        break;
      case "3":
        hapusKegiatan();
        break;
      case "0":
        print("👋 Keluar.");
        break;
      default:
        print("❌ Pilih 0-3!");
    }
    if (pilihan != "0") {
      print("\nTekan Enter...");
      stdin.readLineSync();
    }
  }
}

void main() {
  muatDariJson();
  print("\n" + "=" * 30);
  print("      📅 AGENDA HARIAN");
  print("      Kelompok 7 - Dart");
  print("=" * 30);
  jalankan();
}