
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