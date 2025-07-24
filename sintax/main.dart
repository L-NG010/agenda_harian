// Import paket buat file dan JSON
import 'dart:io';
import 'dart:convert';

// Enum buat tingkat prioritas
enum TingkatPrioritas { rendah, sedang, tinggi, mendesak }

// Class buat nyimpan data kegiatan
class Kegiatan {
  String nama;
  DateTime waktu;
  TingkatPrioritas prioritas;
  String? catatan;

  // Constructor buat bikin kegiatan baru
  Kegiatan({
    required this.nama,
    required this.waktu,
    required this.prioritas,
    this.catatan,
  });

  // Ubah prioritas jadi angka buat ngurutin
  int get nilaiFrioritas {
    switch (prioritas) {
      case TingkatPrioritas.rendah: return 1;
      case TingkatPrioritas.sedang: return 2;
      case TingkatPrioritas.tinggi: return 3;
      case TingkatPrioritas.mendesak: return 4;
    }
  }

  // Format waktu jadi jam:menit
  String get jamString {
    String jam = waktu.hour.toString().padLeft(2, '0');
    String menit = waktu.minute.toString().padLeft(2, '0');
    return "$jam:$menit";
  }

  // Format prioritas jadi text
  String get prioritasString {
    switch (prioritas) {
      case TingkatPrioritas.rendah: return "Rendah";
      case TingkatPrioritas.sedang: return "Sedang";
      case TingkatPrioritas.tinggi: return "Tinggi";
      case TingkatPrioritas.mendesak: return "Mendesak";
    }
  }

  // Ubah jadi JSON buat disimpan
  Map<String, dynamic> keJSON() {
    return {
      'nama': nama,
      'waktu': waktu.millisecondsSinceEpoch,
      'prioritas': prioritas.index,
      'catatan': catatan,
    };
  }

  // Bikin kegiatan dari JSON
  static Kegiatan dariJSON(Map<String, dynamic> json) {
    return Kegiatan(
      nama: json['nama'],
      waktu: DateTime.fromMillisecondsSinceEpoch(json['waktu']),
      prioritas: TingkatPrioritas.values[json['prioritas']],
      catatan: json['catatan'],
    );
  }
}

// Class utama buat ngatur agenda
class AgendaKu {
  List<Kegiatan> daftarKegiatan = [];
  String namaFile = 'agenda_ku.json';

  // Constructor - langsung muat data kalo ada
  AgendaKu() {
    muatData();
  }

  // Simpan data ke file
  void simpanData() {
    try {
      File file = File(namaFile);
      List<Map<String, dynamic>> data = daftarKegiatan.map((k) => k.keJSON()).toList();
      
      Map<String, dynamic> semuaData = {
        'tanggal_simpan': DateTime.now().toIso8601String(),
        'jumlah': daftarKegiatan.length,
        'kegiatan': data,
      };

      file.writeAsStringSync(jsonEncode(semuaData));
      print("✅ Data udah disimpan!");
    } catch (e) {
      print("❌ Gagal nyimpan: $e");
    }
  }

  // Muat data dari file
  void muatData() {
    try {
      File file = File(namaFile);
      if (file.existsSync()) {
        String isi = file.readAsStringSync();
        Map<String, dynamic> data = jsonDecode(isi);
        
        if (data.containsKey('kegiatan')) {
          List<dynamic> listKegiatan = data['kegiatan'];
          daftarKegiatan = listKegiatan.map((k) => Kegiatan.dariJSON(k)).toList();
          print("📁 Berhasil muat ${listKegiatan.length} kegiatan");
        }
      } else {
        print("📝 Belum ada file agenda, nanti dibuat otomatis");
      }
    } catch (e) {
      print("❌ Gagal muat data: $e");
      daftarKegiatan = [];
    }
  }

  // Tambah kegiatan baru
  void tambahKegiatan(Kegiatan kegiatan) {
    daftarKegiatan.add(kegiatan);
    simpanData();
    print("✅ Kegiatan '${kegiatan.nama}' udah ditambah!");
  }

  // Hapus kegiatan
  bool hapusKegiatan(int nomor) {
    if (nomor >= 0 && nomor < daftarKegiatan.length) {
      String nama = daftarKegiatan[nomor].nama;
      daftarKegiatan.removeAt(nomor);
      simpanData();
      print("✅ Kegiatan '$nama' udah dihapus!");
      return true;
    }
    return false;
  }

  // Urutin kegiatan berdasarkan prioritas terus waktu
  void urutinKegiatan() {
    daftarKegiatan.sort((a, b) {
      // Prioritas tinggi dulu
      int bandingPrioritas = b.nilaiFrioritas.compareTo(a.nilaiFrioritas);
      if (bandingPrioritas == 0) {
        // Kalo prioritas sama, waktu paling awal dulu
        return a.waktu.compareTo(b.waktu);
      }
      return bandingPrioritas;
    });
  }

  // Getter buat ambil jumlah kegiatan
  int get jumlah => daftarKegiatan.length;
}

// Fungsi buat nampilin agenda dalam bentuk tabel
void tampilkanAgenda(AgendaKu agenda) {
  if (agenda.daftarKegiatan.isEmpty) {
    print("\n❌ Belum ada kegiatan nih!");
    return;
  }

  // Urutin dulu sebelum ditampilin
  agenda.urutinKegiatan();

  print("\n" + "=" * 70);
  print("                📅 AGENDA HARIAN KU");
  print("=" * 70);
  print("| No | Waktu | Kegiatan          | Prioritas | Catatan           |");
  print("|----+-------+-------------------+-----------+-------------------|");

  for (int i = 0; i < agenda.daftarKegiatan.length; i++) {
    Kegiatan k = agenda.daftarKegiatan[i];
    String no = "${i + 1}".padLeft(2);
    String waktu = k.jamString;
    String nama = k.nama.length > 17 ? "${k.nama.substring(0, 14)}..." : k.nama;
    String prioritas = k.prioritasString;
    String catatan = k.catatan ?? "";
    if (catatan.length > 17) catatan = "${catatan.substring(0, 14)}...";

    print("| $no | $waktu | ${nama.padRight(17)} | ${prioritas.padRight(9)} | ${catatan.padRight(17)} |");
  }

  print("=" * 70);
  print("Total: ${agenda.jumlah} kegiatan");
}

// Nampilin menu utama
void tampilkanMenu() {
  print("\n🏠 MENU UTAMA:");
  print("1. Tambah Kegiatan Baru");
  print("2. Lihat Semua Agenda");
  print("3. Hapus Kegiatan");
  print("0. Keluar Aplikasi");
  print("\nPilih menu (0-3): ");
}

// Parsing input waktu dari string ke DateTime
DateTime parseJam(String input) {
  try {
    List<String> bagian = input.split(':');
    if (bagian.length != 2) throw FormatException("Format salah");

    int jam = int.parse(bagian[0]);
    int menit = int.parse(bagian[1]);

    if (jam < 0 || jam > 23 || menit < 0 || menit > 59) {
      throw FormatException("Jam tidak valid");
    }

    DateTime sekarang = DateTime.now();
    return DateTime(sekarang.year, sekarang.month, sekarang.day, jam, menit);
  } catch (e) {
    throw FormatException("Format jam salah! Pake format JJ:MM (contoh: 14:30)");
  }
}

// Parsing input prioritas
TingkatPrioritas parsePrioritas(String? input) {
  switch (input) {
    case '1': return TingkatPrioritas.rendah;
    case '2': return TingkatPrioritas.sedang;
    case '3': return TingkatPrioritas.tinggi;
    case '4': return TingkatPrioritas.mendesak;
    default:
      print("⚠️ Prioritas ga valid, pake prioritas Sedang aja ya");
      return TingkatPrioritas.sedang;
  }
}

// Fungsi buat nambah kegiatan baru
void tambahKegiatanBaru(AgendaKu agenda) {
  try {
    print("\n➕ TAMBAH KEGIATAN BARU");
    print("-" * 25);

    // Input nama kegiatan
    print("Nama kegiatan: ");
    String? nama = stdin.readLineSync();
    if (nama == null || nama.trim().isEmpty) {
      print("❌ Nama kegiatan jangan kosong dong!");
      return;
    }

    // Input waktu
    print("Waktu (contoh: 14:30): ");
    String? inputWaktu = stdin.readLineSync();
    if (inputWaktu == null) {
      print("❌ Waktu ga valid!");
      return;
    }
    DateTime waktu = parseJam(inputWaktu);

    // Input prioritas
    print("Pilih prioritas:");
    print("1. Rendah (santai aja)");
    print("2. Sedang (biasa)");
    print("3. Tinggi (penting nih)");
    print("4. Mendesak (urgent banget!)");
    print("Pilih (1-4): ");
    String? inputPrioritas = stdin.readLineSync();
    TingkatPrioritas prioritas = parsePrioritas(inputPrioritas);

    // Input catatan opsional
    print("Catatan tambahan (boleh kosong): ");
    String? catatan = stdin.readLineSync();

    // Bikin objek kegiatan baru
    Kegiatan kegiatanBaru = Kegiatan(
      nama: nama.trim(),
      waktu: waktu,
      prioritas: prioritas,
      catatan: catatan?.trim().isEmpty == true ? null : catatan?.trim(),
    );

    // Tambah ke agenda
    agenda.tambahKegiatan(kegiatanBaru);
  } catch (e) {
    print("❌ Ada error: $e");
  }
}

// Fungsi buat hapus kegiatan
void hapusKegiatan(AgendaKu agenda) {
  if (agenda.jumlah == 0) {
    print("\n❌ Ga ada kegiatan yang bisa dihapus!");
    return;
  }

  // Tampilin agenda dulu
  tampilkanAgenda(agenda);

  print("\nMau hapus kegiatan nomor berapa? (1-${agenda.jumlah}): ");
  String? input = stdin.readLineSync();

  try {
    int nomor = int.parse(input!) - 1;
    if (!agenda.hapusKegiatan(nomor)) {
      print("❌ Nomor ga valid!");
    }
  } catch (e) {
    print("❌ Input harus angka ya!");
  }
}

// Fungsi utama - main program
void main() {
  AgendaKu agendaKu = AgendaKu();

  // Tampilan pembuka
  print("\n" + "=" * 60);
  print("         📅 APLIKASI AGENDA HARIAN KU");
  print("              Versi Sederhana");
  print("      Kelompok 7 - Pemrograman Dart");
  print("=" * 60);

  // Loop utama program
  while (true) {
    tampilkanMenu();
    String? pilihan = stdin.readLineSync();

    switch (pilihan) {
      case '1':
        tambahKegiatanBaru(agendaKu);
        break;
      case '2':
        tampilkanAgenda(agendaKu);
        break;
      case '3':
        hapusKegiatan(agendaKu);
        break;
      case '0':
        print("\n💾 Lagi nyimpan data...");
        agendaKu.simpanData();
        print("👋 Makasih udah pake Agenda Harian Ku!");
        print("Sampai jumpa lagi! 😊");
        return;
      default:
        print("\n❌ Pilihan ga valid! Pilih angka 0-3 aja ya.");
    }

    print("\nTekan Enter buat lanjut...");
    stdin.readLineSync();
  }
}
// halo saya galih