class BankOption {
  final String name;
  final String bin;
  const BankOption(this.name, this.bin);
}

class VietQrService {
  static const List<BankOption> banks = [
    BankOption('Vietcombank', '970436'),
    BankOption('Techcombank', '970407'),
    BankOption('MB Bank', '970422'),
    BankOption('BIDV', '970418'),
    BankOption('VietinBank', '970415'),
    BankOption('ACB', '970416'),
    BankOption('TPBank', '970423'),
    BankOption('VPBank', '970432'),
    BankOption('Sacombank', '970403'),
    BankOption('MSB', '970426'),
    BankOption('VIB', '970441'),
    BankOption('Agribank', '970405'),
  ];

  static String? imageUrl({
    required String bankBin,
    required String accountNo,
    required String accountName,
    double? amount,
    String? addInfo,
  }) {
    if (bankBin.isEmpty || accountNo.isEmpty) return null;
    final encodedName = Uri.encodeComponent(accountName);
    final info = Uri.encodeComponent(addInfo ?? 'Ví Xinh');
    final amt = (amount != null && amount > 0) ? amount.toInt().toString() : '';
    final amtQuery = amt.isEmpty ? '' : '&amount=$amt';
    return 'https://img.vietqr.io/image/$bankBin-$accountNo-compact2.png?accountName=$encodedName&addInfo=$info$amtQuery';
  }
}
