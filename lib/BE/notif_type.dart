/// Notification / approval `tipe` codes from backend.
/// Keep these identical to the server enum.
abstract class NotifType {
  // Purchase
  static const sc = 'SC'; // SPPBJ Confirmation
  static const sa = 'SA'; // SPPBJ Approval
  static const pa = 'PA'; // PO SCM Approval
  static const poe = 'POE'; // PO SCM Exception Approval
  static const pne = 'PNE'; // PO NON SCM Exception Approval
  static const pos = 'POS'; // PO SCM Unapprove Approval
  static const pns = 'PNS'; // PO NON SCM Unapprove Approval

  /// API path segment for PO exception endpoints (`poscm` / `pononscm`).
  static String poExceptionApiSegment(String? type) {
    switch ((type ?? '').trim().toUpperCase()) {
      case pne:
        return 'pononscm';
      case poe:
      default:
        return 'poscm';
    }
  }

  static String poExceptionLabel(String? type) {
    switch ((type ?? '').trim().toUpperCase()) {
      case pne:
        return 'PO Non SCM';
      case poe:
        return 'PO SCM';
      default:
        return 'PO Exception';
    }
  }

  // Cash & Bank (kasbon / lpjk)
  static const kc = 'KC'; // kasbon confirmation
  static const ka = 'KA'; // kasbon approval
  static const kda = 'KDA'; // kasbon disb. approval
  static const kd = 'KD'; // kasbon disbursement
  static const lc = 'LC'; // lpjk confirmation
  static const la = 'LA'; // lpjk approval
  static const lda = 'LDA'; // lpjk disb approval
  static const ld = 'LD'; // lpjk disbursement

  // Inventory
  static const mua = 'MUA'; // mu approval
  static const ita = 'ITA'; // it approval
  static const mra = 'MRA'; // mr approval
  static const gra = 'GRA'; // gr approval
  static const sta = 'STA'; // stock transfer approval
  static const sma = 'SMA'; // stock movement approval
  static const saa = 'SAA'; // stock adjustment approval
  static const spa = 'SPA'; // stock price adj approval
  static const mmu = 'MMU'; // min max update
  static const stua = 'STUA'; // stock top up approval
  static const aa = 'AA'; // assembling approval
  static const itsa = 'ITSA'; // it adjustment approval
  static const stsa = 'STSA'; // st adjustment approval

  // Purchase / A/P extras
  static const dna = 'DNA'; // debit notes approval
  static const apra = 'APRA'; // ap refund approval
  static const dpa = 'DPA'; // dp approval
  static const apaa = 'APAA'; // ap adjustment approval
  static const na = 'NA'; // newap approval

  // Sales
  static const soa = 'SOA'; // sales order approval
  static const arra = 'ARRA'; // ar receipt approval

  // PPC
  static const woa = 'WOA'; // wo approval
  static const wou = 'WOU'; // wo update
}
