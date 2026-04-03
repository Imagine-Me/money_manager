class IndianBank {
  const IndianBank({required this.name, required this.code, this.shortName});

  final String name;
  final String code;
  final String? shortName;

  String get displayName => shortName ?? name;
}

class IndianBanks {
  IndianBanks._();

  static const List<IndianBank> all = [
    // ─── Public Sector Banks ──────────────────────────────────────────────────
    IndianBank(name: 'State Bank of India', code: 'sbi', shortName: 'SBI'),
    IndianBank(name: 'Bank of Baroda', code: 'bob', shortName: 'BoB'),
    IndianBank(name: 'Bank of India', code: 'boi', shortName: 'BoI'),
    IndianBank(name: 'Bank of Maharashtra', code: 'bom', shortName: 'BoM'),
    IndianBank(name: 'Canara Bank', code: 'canara'),
    IndianBank(name: 'Central Bank of India', code: 'central'),
    IndianBank(name: 'Indian Bank', code: 'indian'),
    IndianBank(name: 'Indian Overseas Bank', code: 'iob', shortName: 'IOB'),
    IndianBank(name: 'Punjab & Sind Bank', code: 'psb', shortName: 'PSB'),
    IndianBank(name: 'Punjab National Bank', code: 'pnb', shortName: 'PNB'),
    IndianBank(name: 'UCO Bank', code: 'uco'),
    IndianBank(name: 'Union Bank of India', code: 'union'),
    // ─── Private Sector Banks ─────────────────────────────────────────────────
    IndianBank(name: 'Axis Bank', code: 'axis'),
    IndianBank(name: 'Bandhan Bank', code: 'bandhan'),
    IndianBank(name: 'Catholic Syrian Bank', code: 'csb', shortName: 'CSB'),
    IndianBank(name: 'City Union Bank', code: 'cub', shortName: 'CUB'),
    IndianBank(name: 'DCB Bank', code: 'dcb'),
    IndianBank(name: 'Dhanlaxmi Bank', code: 'dhanlaxmi'),
    IndianBank(name: 'Federal Bank', code: 'federal'),
    IndianBank(name: 'HDFC Bank', code: 'hdfc', shortName: 'HDFC'),
    IndianBank(name: 'ICICI Bank', code: 'icici', shortName: 'ICICI'),
    IndianBank(name: 'IDBI Bank', code: 'idbi', shortName: 'IDBI'),
    IndianBank(name: 'IDFC FIRST Bank', code: 'idfc', shortName: 'IDFC'),
    IndianBank(name: 'IndusInd Bank', code: 'indusind'),
    IndianBank(name: 'Jammu & Kashmir Bank', code: 'jkb', shortName: 'J&K Bank'),
    IndianBank(name: 'Karnataka Bank', code: 'karnataka'),
    IndianBank(name: 'Karur Vysya Bank', code: 'kvb', shortName: 'KVB'),
    IndianBank(
        name: 'Kotak Mahindra Bank', code: 'kotak', shortName: 'Kotak'),
    IndianBank(name: 'Nainital Bank', code: 'nainital'),
    IndianBank(name: 'RBL Bank', code: 'rbl'),
    IndianBank(name: 'South Indian Bank', code: 'sib', shortName: 'SIB'),
    IndianBank(
        name: 'Tamilnad Mercantile Bank', code: 'tmb', shortName: 'TMB'),
    IndianBank(name: 'Yes Bank', code: 'yes'),
    // ─── Small Finance Banks ──────────────────────────────────────────────────
    IndianBank(
        name: 'AU Small Finance Bank', code: 'au', shortName: 'AU SFB'),
    IndianBank(name: 'Capital Small Finance Bank', code: 'capital'),
    IndianBank(name: 'Equitas Small Finance Bank', code: 'equitas'),
    IndianBank(
        name: 'ESAF Small Finance Bank', code: 'esaf', shortName: 'ESAF'),
    IndianBank(name: 'Jana Small Finance Bank', code: 'jana'),
    IndianBank(name: 'Suryoday Small Finance Bank', code: 'suryoday'),
    IndianBank(
        name: 'Ujjivan Small Finance Bank',
        code: 'ujjivan',
        shortName: 'Ujjivan'),
    IndianBank(name: 'Unity Small Finance Bank', code: 'unity'),
    IndianBank(name: 'Utkarsh Small Finance Bank', code: 'utkarsh'),
    // ─── Payment Banks ────────────────────────────────────────────────────────
    IndianBank(name: 'Airtel Payments Bank', code: 'airtel'),
    IndianBank(name: 'Fino Payments Bank', code: 'fino'),
    IndianBank(
        name: 'India Post Payments Bank', code: 'ippb', shortName: 'IPPB'),
    IndianBank(name: 'NSDL Payments Bank', code: 'nsdl'),
    IndianBank(name: 'Paytm Payments Bank', code: 'paytm'),
    // ─── Digital / Neo Banks ──────────────────────────────────────────────────
    IndianBank(name: 'Fi Money', code: 'fi'),
    IndianBank(name: 'Jupiter', code: 'jupiter'),
    IndianBank(name: 'Navi', code: 'navi'),
    IndianBank(name: 'Niyo', code: 'niyo'),
    IndianBank(name: 'Groww', code: 'groww'),
    IndianBank(name: 'Zerodha', code: 'zerodha'),
    // ─── Other ────────────────────────────────────────────────────────────────
    IndianBank(name: 'Cash / Wallet', code: 'cash'),
    IndianBank(name: 'Other', code: 'other'),
  ];

  static IndianBank? findByCode(String code) {
    try {
      return all.firstWhere((b) => b.code == code);
    } catch (_) {
      return null;
    }
  }

  static List<IndianBank> search(String query) {
    if (query.isEmpty) return all;
    final q = query.toLowerCase().trim();
    return all
        .where((b) =>
            b.name.toLowerCase().contains(q) ||
            (b.shortName?.toLowerCase().contains(q) ?? false) ||
            b.code.toLowerCase().contains(q))
        .toList();
  }
}
