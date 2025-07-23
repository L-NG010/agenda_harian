import 'dart:io';
import 'agenda.dart';
import 'kegiatan.dart';

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
          await hapusKegiatan();
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
    print("\n" + "=" * 60);
    print("        📅 APLIKASI AGENDA HARIAN DENGAN PRIORITAS");
    print("                   Kelompok 7");
    print("    Lang - Alfian - Ashila - Fira - Galih");
    print("=" * 60);
  }

  void tampilkanMenu() {
    print("\n📋 MENU UTAMA:");
    print("1. Tambah Kegiatan");
    print("2. Tampilkan Agenda");
    print("3. Hapus Kegiatan");
    print("0. Keluar");
    print("\nPilih opsi (0-3): ");
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
    print(
        "\nMasukkan nomor kegiatan yang akan dihapus (1-${agenda.jumlahKegiatan}): ");
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
}

void main() {
  AgendaInterface app = AgendaInterface();
  app.jalankan();
}
// tes