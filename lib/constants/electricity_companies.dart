class ElectricityCompany {
  final String code;
  final String name;
  final String shortName;
  final int regionNo;
  final List<String> cities;
  final int population;
  final String operator;

  const ElectricityCompany({
    required this.code,
    required this.name,
    required this.shortName,
    required this.regionNo,
    required this.cities,
    required this.population,
    required this.operator,
  });
}

const List<ElectricityCompany> electricityCompanies = [
  ElectricityCompany(
    code: "BEDAS",
    name: "Boğaziçi Elektrik Dağıtım A.Ş.",
    shortName: "BEDAŞ",
    regionNo: 17,
    cities: ["İstanbul (Avrupa Yakası)"],
    population: 9162919,
    operator: "Cengiz + Limak + Kolin",
  ),
  ElectricityCompany(
    code: "TOROSLAR",
    name: "Toroslar Elektrik Dağıtım A.Ş.",
    shortName: "TOROSLAR EDAŞ",
    regionNo: 7,
    cities: ["Adana", "Gaziantep", "Mersin", "Hatay", "Osmaniye", "Kilis"],
    population: 7830105,
    operator: "Enerjisa",
  ),
  ElectricityCompany(
    code: "BASKENT",
    name: "Başkent Elektrik Dağıtım A.Ş.",
    shortName: "BAŞKENT EDAŞ",
    regionNo: 9,
    cities: [
      "Ankara",
      "Zonguldak",
      "Kastamonu",
      "Kırıkkale",
      "Karabük",
      "Çankırı",
      "Bartın",
    ],
    population: 6899700,
    operator: "Enerjisa",
  ),
  ElectricityCompany(
    code: "DICLE",
    name: "Dicle Elektrik Dağıtım A.Ş.",
    shortName: "DİCLE EDAŞ",
    regionNo: 1,
    cities: ["Şanlıurfa", "Diyarbakır", "Mardin", "Batman", "Şırnak", "Siirt"],
    population: 5526144,
    operator: "Eksim Holding",
  ),
  ElectricityCompany(
    code: "GEDIZ",
    name: "Gediz Elektrik Dağıtım A.Ş.",
    shortName: "GEDİZ EDAŞ",
    regionNo: 11,
    cities: ["İzmir", "Manisa"],
    population: 5420537,
    operator: "Bereket Enerji",
  ),
  ElectricityCompany(
    code: "AYEDAS",
    name: "Anadolu Yakası Elektrik Dağıtım A.Ş.",
    shortName: "AYEDAŞ",
    regionNo: 14,
    cities: ["İstanbul (Anadolu Yakası)"],
    population: 4997548,
    operator: "Enerjisa",
  ),
  ElectricityCompany(
    code: "ULUDAG",
    name: "Uludağ Elektrik Dağıtım A.Ş.",
    shortName: "ULUDAĞ EDAŞ",
    regionNo: 12,
    cities: ["Bursa", "Balıkesir", "Çanakkale", "Yalova"],
    population: 4626181,
    operator: "Limak + Cengiz + Kolin",
  ),
  ElectricityCompany(
    code: "MERAM",
    name: "Meram Elektrik Dağıtım A.Ş.",
    shortName: "MEDAŞ",
    regionNo: 8,
    cities: ["Konya", "Aksaray", "Niğde", "Nevşehir", "Karaman", "Kırşehir"],
    population: 3552586,
    operator: "Alarko + Cengiz",
  ),
  ElectricityCompany(
    code: "SAKARYA",
    name: "Sakarya Elektrik Dağıtım A.Ş.",
    shortName: "SEDAŞ",
    regionNo: 15,
    cities: ["Kocaeli", "Sakarya", "Düzce", "Bolu"],
    population: 3228580,
    operator: "Akenerji + CEZ",
  ),
  ElectricityCompany(
    code: "YESILIRMAK",
    name: "Yeşilırmak Elektrik Dağıtım A.Ş.",
    shortName: "YEDAŞ",
    regionNo: 21,
    cities: ["Samsun", "Ordu", "Çorum", "Amasya", "Sinop"],
    population: 3051887,
    operator: "Çalık Holding",
  ),
  ElectricityCompany(
    code: "AYDEM",
    name: "Aydem Elektrik Dağıtım A.Ş.",
    shortName: "AYDEM EDAŞ",
    regionNo: 19,
    cities: ["Aydın", "Denizli", "Muğla"],
    population: 2851086,
    operator: "Bereket Enerji",
  ),
  ElectricityCompany(
    code: "AKDENIZ",
    name: "Akdeniz Elektrik Dağıtım A.Ş.",
    shortName: "AKDENİZ EDAŞ",
    regionNo: 10,
    cities: ["Antalya", "Isparta", "Burdur"],
    population: 2833306,
    operator: "Cengiz + Kolin + Limak",
  ),
  ElectricityCompany(
    code: "OSMANGAZI",
    name: "Osmangazi Elektrik Dağıtım A.Ş.",
    shortName: "OEDAŞ",
    regionNo: 16,
    cities: ["Eskişehir", "Afyonkarahisar", "Kütahya", "Uşak", "Bilecik"],
    population: 2634302,
    operator: "Zorlu Enerji",
  ),
  ElectricityCompany(
    code: "ARAS",
    name: "Aras Elektrik Dağıtım A.Ş.",
    shortName: "ARAS EDAŞ",
    regionNo: 3,
    cities: [
      "Erzurum",
      "Ağrı",
      "Kars",
      "Erzincan",
      "Iğdır",
      "Ardahan",
      "Bayburt",
    ],
    population: 2207602,
    operator: "Çalık + Kiler",
  ),
  ElectricityCompany(
    code: "VANGOLU",
    name: "Vangölü Elektrik Dağıtım A.Ş.",
    shortName: "VEDAŞ",
    regionNo: 2,
    cities: ["Van", "Muş", "Bitlis", "Hakkari"],
    population: 2092863,
    operator: "Türkerler Holding",
  ),
  ElectricityCompany(
    code: "CORUH",
    name: "Çoruh Elektrik Dağıtım A.Ş.",
    shortName: "ÇORUH EDAŞ",
    regionNo: 4,
    cities: ["Trabzon", "Giresun", "Rize", "Artvin", "Gümüşhane"],
    population: 1822195,
    operator: "Aksa Enerji",
  ),
  ElectricityCompany(
    code: "FIRAT",
    name: "Fırat Elektrik Dağıtım A.Ş.",
    shortName: "FIRAT EDAŞ",
    regionNo: 5,
    cities: ["Malatya", "Elazığ", "Bingöl", "Tunceli"],
    population: 1681719,
    operator: "Aksa Enerji",
  ),
  ElectricityCompany(
    code: "AKEDAS",
    name: "Akedaş Elektrik Dağıtım A.Ş.",
    shortName: "AKEDAŞ",
    regionNo: 20,
    cities: ["Kahramanmaraş", "Adıyaman"],
    population: 1672890,
    operator: "Kipaş Holding",
  ),
  ElectricityCompany(
    code: "CAMLIBEL",
    name: "Çamlıbel Elektrik Dağıtım A.Ş.",
    shortName: "ÇEDAŞ",
    regionNo: 6,
    cities: ["Sivas", "Tokat", "Yozgat"],
    population: 1666743,
    operator: "Kolin + Limak + Cengiz",
  ),
  ElectricityCompany(
    code: "TRAKYA",
    name: "Trakya Elektrik Dağıtım A.Ş.",
    shortName: "TREDAŞ",
    regionNo: 13,
    cities: ["Tekirdağ", "Kırklareli", "Edirne"],
    population: 1613616,
    operator: "IC İçtaş Enerji",
  ),
  ElectricityCompany(
    code: "KAYSERI",
    name: "Kayseri ve Civarı Elektrik Türk A.Ş.",
    shortName: "KCETAŞ",
    regionNo: 18,
    cities: ["Kayseri"],
    population: 1295355,
    operator: "Kayseri Büyükşehir Belediyesi",
  ),
];

final Map<String, ElectricityCompany> cityToCompany = {
  for (var company in electricityCompanies)
    for (var city in company.cities) city.toLowerCase(): company,
};

ElectricityCompany? getCompanyByCode(String code) {
  try {
    return electricityCompanies.firstWhere(
      (c) => c.code.toLowerCase() == code.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
}

ElectricityCompany? getCompanyByCity(String city) {
  return cityToCompany[city.toLowerCase()];
}

class WaterUtility {
  final String code;
  final String fullName;
  final String shortName;
  final List<String> cities;
  final String website;

  const WaterUtility({
    required this.code,
    required this.fullName,
    required this.shortName,
    required this.cities,
    required this.website,
  });
}
const List<WaterUtility> waterUtilities = [
  WaterUtility(
    code: "ISKI",
    fullName: "İstanbul Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "İSKİ",
    cities: ["İstanbul"],
    website: "https://www.iski.istanbul",
  ),
  WaterUtility(
    code: "IZSU",
    fullName: "İzmir Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "İZSU",
    cities: ["İzmir"],
    website: "https://www.izsu.gov.tr",
  ),
  WaterUtility(
    code: "ASKI",
    fullName: "Ankara Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "ASKİ",
    cities: ["Ankara"],
    website: "https://www.aski.gov.tr",
  ),
  WaterUtility(
    code: "ASAT",
    fullName: "Antalya Su ve Atıksu İdaresi Genel Müdürlüğü",
    shortName: "ASAT",
    cities: ["Antalya"],
    website: "https://www.asat.gov.tr",
  ),
  WaterUtility(
    code: "BUSKI",
    fullName: "Bursa Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "BUSKİ",
    cities: ["Bursa"],
    website: "https://www.buski.gov.tr",
  ),
  WaterUtility(
    code: "KOSKI",
    fullName: "Konya Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "KOSKİ",
    cities: ["Konya"],
    website: "https://www.koski.gov.tr",
  ),
  WaterUtility(
    code: "MASKI",
    fullName: "Manisa Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "MASKİ",
    cities: ["Manisa"],
    website: "https://www.maski.gov.tr",
  ),
  WaterUtility(
    code: "HATSU",
    fullName: "Hatay Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "HATSU",
    cities: ["Hatay"],
    website: "https://www.hatsu.gov.tr",
  ),
  WaterUtility(
    code: "MESKI",
    fullName: "Mersin Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "MESKİ",
    cities: ["Mersin"],
    website: "https://www.meski.gov.tr",
  ),
  WaterUtility(
    code: "ADESU",
    fullName: "Adana Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "ADESU",
    cities: ["Adana"],
    website: "https://www.adesu.gov.tr",
  ),
  WaterUtility(
    code: "ESKI",
    fullName: "Eskişehir Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "ESKİ",
    cities: ["Eskişehir"],
    website: "https://www.eski.gov.tr",
  ),
  WaterUtility(
    code: "ASKI_AYDIN",
    fullName: "Aydın Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "ASKİ Aydın",
    cities: ["Aydın"],
    website: "https://www.aski.aydin.bel.tr",
  ),
  WaterUtility(
    code: "DESKI",
    fullName: "Denizli Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "DESKİ",
    cities: ["Denizli"],
    website: "https://www.deski.gov.tr",
  ),
  WaterUtility(
    code: "TUSKI",
    fullName: "Tekirdağ Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "TÜSKİ",
    cities: ["Tekirdağ"],
    website: "https://www.tuski.gov.tr",
  ),
  WaterUtility(
    code: "SASKI",
    fullName: "Sakarya Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "SASKİ",
    cities: ["Sakarya"],
    website: "https://www.saski.gov.tr",
  ),
  WaterUtility(
    code: "KASKI",
    fullName: "Kayseri Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "KASKİ",
    cities: ["Kayseri"],
    website: "https://www.kaski.gov.tr",
  ),
  WaterUtility(
    code: "SUSKI",
    fullName: "Şanlıurfa Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "ŞUSKİ",
    cities: ["Şanlıurfa"],
    website: "https://suski.sanliurfa.bel.tr",
  ),
  WaterUtility(
    code: "DISKI",
    fullName: "Diyarbakır Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "DİSKİ",
    cities: ["Diyarbakır"],
    website: "https://www.diski.gov.tr",
  ),
  WaterUtility(
    code: "GASKI",
    fullName: "Gaziantep Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "GASKİ",
    cities: ["Gaziantep"],
    website: "https://www.gaski.gov.tr",
  ),
  WaterUtility(
    code: "MUSKI",
    fullName: "Muğla Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "MUSKİ",
    cities: ["Muğla"],
    website: "https://www.muski.gov.tr",
  ),
  WaterUtility(
    code: "BASKI",
    fullName: "Balıkesir Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "BASKİ",
    cities: ["Balıkesir"],
    website: "https://www.baski.gov.tr",
  ),
  WaterUtility(
    code: "ISU",
    fullName: "Kocaeli Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "İSU",
    cities: ["Kocaeli"],
    website: "https://www.isu.gov.tr",
  ),
  WaterUtility(
    code: "TISKI",
    fullName: "Trabzon Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "TİSKİ",
    cities: ["Trabzon"],
    website: "https://www.tiski.gov.tr",
  ),
  WaterUtility(
    code: "VASKI",
    fullName: "Van Su ve Kanalizasyon İdaresi Genel Müdürlüğü",
    shortName: "VASKİ",
    cities: ["Van"],
    website: "https://www.vaski.gov.tr",
  ),
  WaterUtility(
    code: "OSKI",
    fullName: "Ordu Su ve Kanalizasyon İdaresi",
    shortName: "OSKİ",
    cities: ["Ordu"],
    website: "https://www.oski.gov.tr",
  ),
  WaterUtility(
    code: "AGRI_SU",
    fullName: "Ağrı Su ve Kanalizasyon Müdürlüğü",
    shortName: "AĞRI SU",
    cities: ["Ağrı"],
    website: "https://www.agri.bel.tr",
  ),
  WaterUtility(
    code: "AKSARAY_SU",
    fullName: "Aksaray Su ve Kanalizasyon İdaresi",
    shortName: "AKSARAY SU",
    cities: ["Aksaray"],
    website: "https://www.aksaray.bel.tr",
  ),
  WaterUtility(
    code: "AMASYA_SU",
    fullName: "Amasya Su ve Kanalizasyon Müdürlüğü",
    shortName: "AMASYA SU",
    cities: ["Amasya"],
    website: "https://www.amasya.bel.tr",
  ),
  WaterUtility(
    code: "ARDAHAN_SU",
    fullName: "Ardahan Su ve Kanalizasyon Müdürlüğü",
    shortName: "ARDAHAN SU",
    cities: ["Ardahan"],
    website: "https://www.ardahan.bel.tr",
  ),
  WaterUtility(
    code: "ARTVIN_SU",
    fullName: "Artvin Su ve Kanalizasyon Müdürlüğü",
    shortName: "ARTVİN SU",
    cities: ["Artvin"],
    website: "https://www.artvin.bel.tr",
  ),
  WaterUtility(
    code: "BARTIN_SU",
    fullName: "Bartın Su ve Kanalizasyon Müdürlüğü",
    shortName: "BARTIN SU",
    cities: ["Bartın"],
    website: "https://www.bartin.bel.tr",
  ),
  WaterUtility(
    code: "BATMAN_SU",
    fullName: "Batman Su ve Kanalizasyon İdaresi",
    shortName: "BATMAN SU",
    cities: ["Batman"],
    website: "https://www.batman.bel.tr",
  ),
  WaterUtility(
    code: "BAYBURT_SU",
    fullName: "Bayburt Su ve Kanalizasyon Müdürlüğü",
    shortName: "BAYBURT SU",
    cities: ["Bayburt"],
    website: "https://www.bayburt.bel.tr",
  ),
  WaterUtility(
    code: "BILECIK_SU",
    fullName: "Bilecik Su ve Kanalizasyon Müdürlüğü",
    shortName: "BİLECİK SU",
    cities: ["Bilecik"],
    website: "https://www.bilecik.bel.tr",
  ),
  WaterUtility(
    code: "BINGOL_SU",
    fullName: "Bingöl Su ve Kanalizasyon Müdürlüğü",
    shortName: "BİNGÖL SU",
    cities: ["Bingöl"],
    website: "https://www.bingol.bel.tr",
  ),
  WaterUtility(
    code: "BITLIS_SU",
    fullName: "Bitlis Su ve Kanalizasyon Müdürlüğü",
    shortName: "BİTLİS SU",
    cities: ["Bitlis"],
    website: "https://www.bitlis.bel.tr",
  ),
  WaterUtility(
    code: "BOLU_SU",
    fullName: "Bolu Su ve Kanalizasyon İdaresi",
    shortName: "BOLU SU",
    cities: ["Bolu"],
    website: "https://www.bolu.bel.tr",
  ),
  WaterUtility(
    code: "BURDUR_SU",
    fullName: "Burdur Su ve Kanalizasyon Müdürlüğü",
    shortName: "BURDUR SU",
    cities: ["Burdur"],
    website: "https://www.burdur.bel.tr",
  ),
  WaterUtility(
    code: "CANAKKALE_SU",
    fullName: "Çanakkale Su ve Kanalizasyon İdaresi",
    shortName: "ÇANAKKALE SU",
    cities: ["Çanakkale"],
    website: "https://www.canakkale.bel.tr",
  ),
  WaterUtility(
    code: "CANKIRI_SU",
    fullName: "Çankırı Su ve Kanalizasyon Müdürlüğü",
    shortName: "ÇANKIRI SU",
    cities: ["Çankırı"],
    website: "https://www.cankiri.bel.tr",
  ),
  WaterUtility(
    code: "CORUM_SU",
    fullName: "Çorum Su ve Kanalizasyon İdaresi",
    shortName: "ÇORUM SU",
    cities: ["Çorum"],
    website: "https://www.corum.bel.tr",
  ),
  WaterUtility(
    code: "DUZCE_SU",
    fullName: "Düzce Su ve Kanalizasyon İdaresi",
    shortName: "DÜZCE SU",
    cities: ["Düzce"],
    website: "https://www.duzce.bel.tr",
  ),
  WaterUtility(
    code: "EDIRNE_SU",
    fullName: "Edirne Su ve Kanalizasyon İdaresi",
    shortName: "EDİRNE SU",
    cities: ["Edirne"],
    website: "https://www.edirne.bel.tr",
  ),
  WaterUtility(
    code: "ELAZIG_SU",
    fullName: "Elazığ Su ve Kanalizasyon İdaresi",
    shortName: "ELAZIĞ SU",
    cities: ["Elazığ"],
    website: "https://www.elazig.bel.tr",
  ),
  WaterUtility(
    code: "ERZINCAN_SU",
    fullName: "Erzincan Su ve Kanalizasyon Müdürlüğü",
    shortName: "ERZİNCAN SU",
    cities: ["Erzincan"],
    website: "https://www.erzincan.bel.tr",
  ),
  WaterUtility(
    code: "ERZURUM_SU",
    fullName: "Erzurum Su ve Kanalizasyon İdaresi",
    shortName: "ERZURUM SU",
    cities: ["Erzurum"],
    website: "https://www.erzurum.bel.tr",
  ),
  WaterUtility(
    code: "GIRESUN_SU",
    fullName: "Giresun Su ve Kanalizasyon Müdürlüğü",
    shortName: "GİRESUN SU",
    cities: ["Giresun"],
    website: "https://www.giresun.bel.tr",
  ),
  WaterUtility(
    code: "GUMUSHANE_SU",
    fullName: "Gümüşhane Su ve Kanalizasyon Müdürlüğü",
    shortName: "GÜMÜŞHANE SU",
    cities: ["Gümüşhane"],
    website: "https://www.gumushane.bel.tr",
  ),
  WaterUtility(
    code: "HAKKARI_SU",
    fullName: "Hakkari Su ve Kanalizasyon Müdürlüğü",
    shortName: "HAKKARİ SU",
    cities: ["Hakkari"],
    website: "https://www.hakkari.bel.tr",
  ),
  WaterUtility(
    code: "IGDIR_SU",
    fullName: "Iğdır Su ve Kanalizasyon Müdürlüğü",
    shortName: "IĞDIR SU",
    cities: ["Iğdır"],
    website: "https://www.igdir.bel.tr",
  ),
  WaterUtility(
    code: "ISPARTA_SU",
    fullName: "Isparta Su ve Kanalizasyon İdaresi",
    shortName: "ISPARTA SU",
    cities: ["Isparta"],
    website: "https://www.isparta.bel.tr",
  ),
  WaterUtility(
    code: "KARABUK_SU",
    fullName: "Karabük Su ve Kanalizasyon Müdürlüğü",
    shortName: "KARABÜK SU",
    cities: ["Karabük"],
    website: "https://www.karabuk.bel.tr",
  ),
  WaterUtility(
    code: "KARAMAN_SU",
    fullName: "Karaman Su ve Kanalizasyon İdaresi",
    shortName: "KARAMAN SU",
    cities: ["Karaman"],
    website: "https://www.karaman.bel.tr",
  ),
  WaterUtility(
    code: "KARS_SU",
    fullName: "Kars Su ve Kanalizasyon Müdürlüğü",
    shortName: "KARS SU",
    cities: ["Kars"],
    website: "https://www.kars.bel.tr",
  ),
  WaterUtility(
    code: "KASTAMONU_SU",
    fullName: "Kastamonu Su ve Kanalizasyon Müdürlüğü",
    shortName: "KASTAMONU SU",
    cities: ["Kastamonu"],
    website: "https://www.kastamonu.bel.tr",
  ),
  WaterUtility(
    code: "KILIS_SU",
    fullName: "Kilis Su ve Kanalizasyon İdaresi",
    shortName: "KİLİS SU",
    cities: ["Kilis"],
    website: "https://www.kilis.bel.tr",
  ),
  WaterUtility(
    code: "KIRIKKALE_SU",
    fullName: "Kırıkkale Su ve Kanalizasyon İdaresi",
    shortName: "KIRIKKALE SU",
    cities: ["Kırıkkale"],
    website: "https://www.kirikkale.bel.tr",
  ),
  WaterUtility(
    code: "KIRKLARELI_SU",
    fullName: "Kırklareli Su ve Kanalizasyon İdaresi",
    shortName: "KIRKLARELİ SU",
    cities: ["Kırklareli"],
    website: "https://www.kirklareli.bel.tr",
  ),
  WaterUtility(
    code: "KIRSEHIR_SU",
    fullName: "Kırşehir Su ve Kanalizasyon Müdürlüğü",
    shortName: "KIRŞEHİR SU",
    cities: ["Kırşehir"],
    website: "https://www.kirsehir.bel.tr",
  ),
  WaterUtility(
    code: "KUTAHYA_SU",
    fullName: "Kütahya Su ve Kanalizasyon İdaresi",
    shortName: "KÜTAHYA SU",
    cities: ["Kütahya"],
    website: "https://www.kutahya.bel.tr",
  ),
  WaterUtility(
    code: "MALATYA_SU",
    fullName: "Malatya Su ve Kanalizasyon İdaresi",
    shortName: "MALATYA SU",
    cities: ["Malatya"],
    website: "https://www.malatya.bel.tr",
  ),
  WaterUtility(
    code: "KAHRAMANMARAS_SU",
    fullName: "Kahramanmaraş Su ve Kanalizasyon İdaresi",
    shortName: "K.MARAŞ SU",
    cities: ["Kahramanmaraş"],
    website: "https://www.kahramanmaras.bel.tr",
  ),
  WaterUtility(
    code: "MARDIN_SU",
    fullName: "Mardin Su ve Kanalizasyon Müdürlüğü",
    shortName: "MARDİN SU",
    cities: ["Mardin"],
    website: "https://www.mardin.bel.tr",
  ),
  WaterUtility(
    code: "MUS_SU",
    fullName: "Muş Su ve Kanalizasyon Müdürlüğü",
    shortName: "MUŞ SU",
    cities: ["Muş"],
    website: "https://www.mus.bel.tr",
  ),
  WaterUtility(
    code: "NEVSEHIR_SU",
    fullName: "Nevşehir Su ve Kanalizasyon İdaresi",
    shortName: "NEVŞEHİR SU",
    cities: ["Nevşehir"],
    website: "https://www.nevsehir.bel.tr",
  ),
  WaterUtility(
    code: "NIGDE_SU",
    fullName: "Niğde Su ve Kanalizasyon Müdürlüğü",
    shortName: "NİĞDE SU",
    cities: ["Niğde"],
    website: "https://www.nigde.bel.tr",
  ),
  WaterUtility(
    code: "OSMANIYE_SU",
    fullName: "Osmaniye Su ve Kanalizasyon İdaresi",
    shortName: "OSMANİYE SU",
    cities: ["Osmaniye"],
    website: "https://www.osmaniye.bel.tr",
  ),
  WaterUtility(
    code: "RIZE_SU",
    fullName: "Rize Su ve Kanalizasyon Müdürlüğü",
    shortName: "RİZE SU",
    cities: ["Rize"],
    website: "https://www.rize.bel.tr",
  ),
  WaterUtility(
    code: "SAMSUN_SU",
    fullName: "Samsun Su ve Kanalizasyon İdaresi",
    shortName: "SAMSUN SU",
    cities: ["Samsun"],
    website: "https://www.samsun.bel.tr",
  ),
  WaterUtility(
    code: "SIIRT_SU",
    fullName: "Siirt Su ve Kanalizasyon Müdürlüğü",
    shortName: "SİİRT SU",
    cities: ["Siirt"],
    website: "https://www.siirt.bel.tr",
  ),
  WaterUtility(
    code: "SINOP_SU",
    fullName: "Sinop Su ve Kanalizasyon Müdürlüğü",
    shortName: "SİNOP SU",
    cities: ["Sinop"],
    website: "https://www.sinop.bel.tr",
  ),
  WaterUtility(
    code: "SIRNAK_SU",
    fullName: "Şırnak Su ve Kanalizasyon Müdürlüğü",
    shortName: "ŞIRNAK SU",
    cities: ["Şırnak"],
    website: "https://www.sirnak.bel.tr",
  ),
  WaterUtility(
    code: "SIVAS_SU",
    fullName: "Sivas Su ve Kanalizasyon İdaresi",
    shortName: "SİVAS SU",
    cities: ["Sivas"],
    website: "https://www.sivas.bel.tr",
  ),
  WaterUtility(
    code: "TOKAT_SU",
    fullName: "Tokat Su ve Kanalizasyon Müdürlüğü",
    shortName: "TOKAT SU",
    cities: ["Tokat"],
    website: "https://www.tokat.bel.tr",
  ),
  WaterUtility(
    code: "TUNCELI_SU",
    fullName: "Tunceli Su ve Kanalizasyon Müdürlüğü",
    shortName: "TUNCELİ SU",
    cities: ["Tunceli"],
    website: "https://www.tunceli.bel.tr",
  ),
  WaterUtility(
    code: "USAK_SU",
    fullName: "Uşak Su ve Kanalizasyon İdaresi",
    shortName: "UŞAK SU",
    cities: ["Uşak"],
    website: "https://www.usak.bel.tr",
  ),
  WaterUtility(
    code: "YALOVA_SU",
    fullName: "Yalova Su ve Kanalizasyon İdaresi",
    shortName: "YALOVA SU",
    cities: ["Yalova"],
    website: "https://www.yalova.bel.tr",
  ),
  WaterUtility(
    code: "YOZGAT_SU",
    fullName: "Yozgat Su ve Kanalizasyon Müdürlüğü",
    shortName: "YOZGAT SU",
    cities: ["Yozgat"],
    website: "https://www.yozgat.bel.tr",
  ),
  WaterUtility(
    code: "ZONGULDAK_SU",
    fullName: "Zonguldak Su ve Kanalizasyon İdaresi",
    shortName: "ZONGULDAK SU",
    cities: ["Zonguldak"],
    website: "https://www.zonguldak.bel.tr",
  ),
  WaterUtility(
    code: "ADIYAMAN_SU",
    fullName: "Adıyaman Su ve Kanalizasyon İdaresi",
    shortName: "ADIYAMAN SU",
    cities: ["Adıyaman"],
    website: "https://www.adiyaman.bel.tr",
  ),
  WaterUtility(
    code: "AFYON_SU",
    fullName: "Afyonkarahisar Su ve Kanalizasyon İdaresi",
    shortName: "AFYON SU",
    cities: ["Afyonkarahisar"],
    website: "https://www.afyon.bel.tr",
  ),
];
final Map<String, WaterUtility> cityToWaterUtility = {
  for (var utility in waterUtilities)
    for (var city in utility.cities) city.toLowerCase(): utility,
};
WaterUtility? getWaterUtilityByCode(String code) {
  try {
    return waterUtilities.firstWhere(
      (u) => u.code.toLowerCase() == code.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
}
WaterUtility? getWaterUtilityByCity(String city) {
  return cityToWaterUtility[city.toLowerCase()];
}

class NaturalGasCompany {
  final String code;
  final String fullName;
  final String shortName;
  final List<String> cities;
  final String website;

  const NaturalGasCompany({
    required this.code,
    required this.fullName,
    required this.shortName,
    required this.cities,
    this.website = "",
  });
}
const List<NaturalGasCompany> naturalGasCompanies = [
  NaturalGasCompany(
    code: "IGDAS",
    fullName: "İstanbul Gaz Dağıtım Sanayi ve Ticaret A.Ş.",
    shortName: "İGDAŞ",
    cities: ["İstanbul"],
    website: "https://www.igdas.com.tr",
  ),
  NaturalGasCompany(
    code: "BASKENTGAZ",
    fullName: "Başkentgaz Doğal Gaz Dağıtım A.Ş.",
    shortName: "Başkentgaz",
    cities: ["Ankara"],
    website: "https://www.baskentgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "IZMIRGAZ",
    fullName: "İzmirgaz Dağıtım A.Ş.",
    shortName: "İzmirgaz",
    cities: ["İzmir"],
    website: "https://www.izmirgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "BURSAGAZ",
    fullName: "Bursagaz A.Ş.",
    shortName: "Bursagaz",
    cities: ["Bursa"],
    website: "https://www.bursagaz.com.tr",
  ),
  NaturalGasCompany(
    code: "TOROSGAZ",
    fullName: "Torosgaz Dağıtım A.Ş.",
    shortName: "Torosgaz",
    cities: ["Adana"],
    website: "https://www.torosgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "GASKI_GAZ",
    fullName: "Gaziantep Doğal Gaz Dağıtım A.Ş.",
    shortName: "GASKİ Gaz",
    cities: ["Gaziantep"],
    website: "https://www.gaskigaz.com.tr",
  ),
  NaturalGasCompany(
    code: "KONYAGAZ",
    fullName: "Konyagaz Dağıtım A.Ş.",
    shortName: "Konyagaz",
    cities: ["Konya"],
    website: "https://www.konyagaz.com.tr",
  ),
  NaturalGasCompany(
    code: "KAYSERIGAZ",
    fullName: "Kayserigaz Dağıtım A.Ş.",
    shortName: "Kayserigaz",
    cities: ["Kayseri"],
    website: "https://www.kayserigaz.com.tr",
  ),
  NaturalGasCompany(
    code: "ESKISEHIRGAZ",
    fullName: "Eskişehirgaz Dağıtım A.Ş.",
    shortName: "Eskişehirgaz",
    cities: ["Eskişehir"],
    website: "https://www.eskisehirgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "IZGAZ",
    fullName: "İzgaz Dağıtım A.Ş.",
    shortName: "İzgaz",
    cities: ["Kocaeli"],
    website: "https://www.izgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "AKSA_CUKUROVA",
    fullName: "Aksa Çukurova Doğal Gaz Dağıtım A.Ş.",
    shortName: "Aksa Çukurova",
    cities: ["Adana", "Mersin", "Osmaniye", "Hatay"],
    website: "https://www.aksadogalgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "AKSA_AFYON",
    fullName: "Aksa Afyon Doğalgaz Dağıtım A.Ş.",
    shortName: "Aksa Afyon",
    cities: ["Afyonkarahisar"],
    website: "https://www.aksadogalgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "AKSA_AGRI",
    fullName: "Aksa Ağrı Doğalgaz Dağıtım A.Ş.",
    shortName: "Aksa Ağrı",
    cities: ["Ağrı"],
    website: "https://www.aksadogalgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "AKSA_BALIKESIR",
    fullName: "Aksa Balıkesir Doğalgaz Dağıtım A.Ş.",
    shortName: "Aksa Balıkesir",
    cities: ["Balıkesir"],
    website: "https://www.aksadogalgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "AKSA_BILECIK",
    fullName: "Aksa Bilecik Doğalgaz Dağıtım A.Ş.",
    shortName: "Aksa Bilecik",
    cities: ["Bilecik"],
    website: "https://www.aksadogalgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "AKSA_BOLU",
    fullName: "Aksa Bolu Doğalgaz Dağıtım A.Ş.",
    shortName: "Aksa Bolu",
    cities: ["Bolu"],
    website: "https://www.aksadogalgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "AKSA_CANAKKALE",
    fullName: "Aksa Çanakkale Doğalgaz Dağıtım A.Ş.",
    shortName: "Aksa Çanakkale",
    cities: ["Çanakkale"],
    website: "https://www.aksadogalgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "AKSA_DUZCE",
    fullName: "Aksa Düzce Doğalgaz Dağıtım A.Ş.",
    shortName: "Aksa Düzce",
    cities: ["Düzce"],
    website: "https://www.aksadogalgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "AKSA_KILIS",
    fullName: "Aksa Kilis Doğalgaz Dağıtım A.Ş.",
    shortName: "Aksa Kilis",
    cities: ["Kilis"],
    website: "https://www.aksadogalgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "SAMSEG",
    fullName: "Samsun Doğal Gaz Dağıtım A.Ş.",
    shortName: "SAMSEG",
    cities: ["Samsun"],
    website: "https://www.samseg.com.tr",
  ),
  NaturalGasCompany(
    code: "SODERGAZ",
    fullName: "Sodaş Doğal Gaz Dağıtım A.Ş.",
    shortName: "SODERGAZ",
    cities: ["Sivas"],
    website: "https://www.sodergaz.com.tr",
  ),
  NaturalGasCompany(
    code: "AKSARAYGAZ",
    fullName: "Aksaraygaz Dağıtım A.Ş.",
    shortName: "Aksaraygaz",
    cities: ["Aksaray"],
    website: "https://www.aksaraygaz.com.tr",
  ),
  NaturalGasCompany(
    code: "CAGDASGAZ",
    fullName: "Çağdaş Gaz Dağıtım A.Ş.",
    shortName: "Çağdaşgaz",
    cities: ["Çorum"],
    website: "https://www.cagdasgaz.com.tr",
  ),
  NaturalGasCompany(
    code: "AKMERCAN",
    fullName: "Akmercan Muğla Doğal Gaz Dağıtım Ltd. Şti.",
    shortName: "Akmercan Muğla",
    cities: ["Muğla"],
    website: "https://www.akmercan.com.tr",
  ),
  NaturalGasCompany(
    code: "ANTALYAGAZ",
    fullName: "Antalya Doğal Gaz Dağıtım A.Ş.",
    shortName: "Antalyagaz",
    cities: ["Antalya"],
    website: "https://www.antalyagaz.com.tr",
  ),
];
final Map<String, NaturalGasCompany> cityToNaturalGas = {
  for (var company in naturalGasCompanies)
    for (var city in company.cities) city.toLowerCase(): company,
};
NaturalGasCompany? getNaturalGasCompanyByCode(String code) {
  try {
    return naturalGasCompanies.firstWhere(
      (c) => c.code.toLowerCase() == code.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
}
NaturalGasCompany? getNaturalGasCompanyByCity(String city) {
  return cityToNaturalGas[city.toLowerCase()];
}

class InternetProvider {
  final String code;
  final String fullName;
  final String shortName;
  final String coverage;
  final String website;

  const InternetProvider({
    required this.code,
    required this.fullName,
    required this.shortName,
    required this.coverage,
    this.website = "",
  });
}
const List<InternetProvider> internetProviders = [
  InternetProvider(
    code: "TURKTELEKOM",
    fullName: "Türk Telekomünikasyon A.Ş.",
    shortName: "Türk Telekom",
    coverage: "Ulusal",
    website: "https://www.turktelekom.com.tr",
  ),
  InternetProvider(
    code: "TURKNET",
    fullName: "TurkNet İletişim Hizmetleri A.Ş.",
    shortName: "TurkNet",
    coverage: "Ulusal",
    website: "https://www.turk.net",
  ),
  InternetProvider(
    code: "SUPERONLINE",
    fullName: "Turkcell Superonline",
    shortName: "Superonline",
    coverage: "Ulusal",
    website: "https://www.superonline.net",
  ),
  InternetProvider(
    code: "VODAFONE",
    fullName: "Vodafone Net İletişim Hizmetleri A.Ş.",
    shortName: "Vodafone Net",
    coverage: "Ulusal",
    website: "https://www.vodafonenet.com.tr",
  ),
  InternetProvider(
    code: "MILLENICOM",
    fullName: "Millenicom İletişim Teknoloji Hizmetleri A.Ş.",
    shortName: "MilleniCOM",
    coverage: "Ulusal",
    website: "https://www.millenicom.com.tr",
  ),
  InternetProvider(
    code: "NETSPEED",
    fullName: "Netspeed İnternet İletişim Hizmetleri A.Ş.",
    shortName: "Netspeed",
    coverage: "Ulusal",
    website: "https://www.netspeed.com.tr",
  ),
  InternetProvider(
    code: "TURKSAT",
    fullName: "Türksat Kablo TV ve İletişim A.Ş.",
    shortName: "Türksat Kablonet",
    coverage: "Ulusal",
    website: "https://www.turksat.com.tr",
  ),
  InternetProvider(
    code: "DSMART",
    fullName: "D-Smart İletişim Teknolojileri A.Ş.",
    shortName: "D-Smart Net",
    coverage: "Ulusal",
    website: "https://www.dsmart.com.tr",
  ),
  InternetProvider(
    code: "KABLONET",
    fullName: "Türksat Kablonet",
    shortName: "Kablonet",
    coverage: "Ulusal",
    website: "https://www.kablonet.com.tr",
  ),
  InternetProvider(
    code: "TTNET",
    fullName: "TTNET (Türk Telekom)",
    shortName: "TTNET",
    coverage: "Ulusal",
    website: "https://www.ttnet.com.tr",
  ),
  InternetProvider(
    code: "TURKCELL",
    fullName: "Turkcell İletişim Hizmetleri A.Ş.",
    shortName: "Turkcell Fiber",
    coverage: "Ulusal",
    website: "https://www.turkcell.com.tr",
  ),
  InternetProvider(
    code: "VESTELNET",
    fullName: "Vestelnet",
    shortName: "Vestelnet",
    coverage: "Ulusal",
    website: "https://www.vestelnet.com.tr",
  ),
  InternetProvider(
    code: "COMNET",
    fullName: "Comnet Veri Merkezi",
    shortName: "Comnet",
    coverage: "Ulusal",
    website: "https://www.comnet.com.tr",
  ),
  InternetProvider(
    code: "ALPTELEKOM",
    fullName: "Alp Telekominikasyon",
    shortName: "Alp Telekom",
    coverage: "Bölgesel",
    website: "https://www.alptelekom.com.tr",
  ),
  InternetProvider(
    code: "CAZANET",
    fullName: "Cazanet İletişim",
    shortName: "Cazanet",
    coverage: "Bölgesel",
    website: "https://www.cazanet.com.tr",
  ),
  InternetProvider(
    code: "NETDIREKT",
    fullName: "Netdirekt",
    shortName: "Netdirekt",
    coverage: "Bölgesel",
    website: "https://www.netdirekt.com.tr",
  ),
  InternetProvider(
    code: "TELSIN",
    fullName: "Telsin İletişim",
    shortName: "Telsin",
    coverage: "Bölgesel",
    website: "https://www.telsin.com.tr",
  ),
];
final Map<String, InternetProvider> providerByName = {
  for (var provider in internetProviders)
    provider.shortName.toLowerCase(): provider,
};
InternetProvider? getInternetProviderByCode(String code) {
  try {
    return internetProviders.firstWhere(
      (p) => p.code.toLowerCase() == code.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
}
InternetProvider? getInternetProviderByName(String name) {
  return providerByName[name.toLowerCase()];
}
