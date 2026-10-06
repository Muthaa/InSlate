/// M-Shwari loan transaction clauses, kept separate from savings and marketing.
class MshwariLoanPatterns {
  MshwariLoanPatterns._();

  static final disbursement = RegExp(
    r'^\s*[A-Z0-9]{10}\s+Confirmed\.\s+Your M-Shwari loan(?: top[- ]up)? has been approved on (\d{1,2}/\d{1,2}/\d{2})\s+(?:at\s+)?(\d{1,2}:\d{2}\s*(?:AM|PM)) and Ksh\s*([\d,]+\.\d{2})(?: less excise duty)? has been deposited to your M-PESA account\.',
    caseSensitive: false,
  );

  // Conservative adaptation of the existing confirmed loan-payment wording.
  // Add a real M-Shwari repayment fixture here before expanding this grammar.
  // The source is optional; no M-PESA origin is inferred when it is absent.
  static final repayment = RegExp(
    r'^\s*[A-Z0-9]{10}\s+Confirmed\.\s+Ksh\s*([\d,]+\.\d{2})(?: from your (?:M-PESA|M-Shwari(?: savings)?)(?: account)?)? has been used to (?:fully |partially )?pay your (?:outstanding )?M-Shwari loan(?: on (\d{1,2}/\d{1,2}/\d{2})\s+(?:at\s+)?(\d{1,2}:\d{2}\s*(?:AM|PM)))?\.',
    caseSensitive: false,
  );
}
