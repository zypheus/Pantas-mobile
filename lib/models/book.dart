class Book {
  final String id;
  final String type;
  final String title;
  final String author;
  final String? coverImage;
  final int year;
  final String callNumber;
  final String contentType; // e.g., Book, E-book
  final String section;
  final String availability;
  final bool isAvailable;
  final int totalCopies;
  final int availableCopies;
  final String? libraryName;
  final String? course;
  final String? publisher;
  final String? source;
  final String? link;

  Book({
    required this.id,
    this.type = 'book',
    required this.title,
    required this.author,
    this.coverImage,
    required this.year,
    required this.callNumber,
    required this.contentType,
    required this.section,
    required this.availability,
    required this.isAvailable,
    required this.totalCopies,
    required this.availableCopies,
    this.libraryName,
    this.course,
    this.publisher,
    this.source,
    this.link,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final availability = _stringValue(json['availability']);
    final copies = _intValue(json['copies'], fallback: 0);
    final type = _stringValue(json['type'], fallback: 'book');

    return Book(
      id: _stringValue(json['id']),
      type: type,
      title: _stringValue(json['title'], fallback: 'Untitled'),
      author: _stringValue(json['author'], fallback: 'Unknown author'),
      coverImage: _nullableString(json['cover_url']),
      year: _intValue(json['publication_year'], fallback: 0),
      callNumber: _stringValue(json['call_number']),
      contentType: _stringValue(
        json['content_type'],
        fallback: type == 'ebook' ? 'E-book' : 'Book',
      ),
      section: _stringValue(json['section']),
      availability: availability.isEmpty ? 'Unavailable' : availability,
      isAvailable: availability.toLowerCase() == 'available',
      totalCopies: copies,
      availableCopies: availability.toLowerCase() == 'available' ? copies : 0,
      libraryName: _nullableString(json['library_name']),
      course: _nullableString(json['course'] ?? json['program']),
      publisher: _nullableString(json['publisher']),
      source: _nullableString(json['source']),
      link: _nullableString(json['link']),
    );
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    final stringValue = value?.toString();
    return stringValue == null || stringValue.isEmpty ? fallback : stringValue;
  }

  static String? _nullableString(Object? value) {
    final stringValue = value?.toString();
    return stringValue == null || stringValue.isEmpty ? null : stringValue;
  }

  static int _intValue(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class CatalogPage {
  final List<Book> books;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const CatalogPage({
    required this.books,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory CatalogPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = _asMap(json['meta']);

    return CatalogPage(
      books: data is List
          ? data
                .map((item) => Book.fromJson(_asMap(item)))
                .toList(growable: false)
          : const [],
      currentPage: _intValue(meta['current_page'], fallback: 1),
      perPage: _intValue(meta['per_page'], fallback: 10),
      total: _intValue(meta['total'], fallback: 0),
      lastPage: _intValue(meta['last_page'], fallback: 1),
    );
  }
}

class CatalogFilters {
  final List<String> courses;
  final List<String> contentTypes;
  final List<String> sections;
  final List<String> subjectTopics;
  final List<String> genres;

  const CatalogFilters({
    this.courses = const [],
    this.contentTypes = const [],
    this.sections = const [],
    this.subjectTopics = const [],
    this.genres = const [],
  });

  factory CatalogFilters.fromJson(Map<String, dynamic> json) {
    return CatalogFilters(
      courses: _stringList(json['courses']),
      contentTypes: _stringList(json['content_types']),
      sections: _stringList(json['sections']),
      subjectTopics: _stringList(json['subject_topics']),
      genres: _stringList(json['genres']),
    );
  }
}

class BookDetails {
  final Book book;
  final BookDescription description;
  final List<BookCopy> copies;

  const BookDetails({
    required this.book,
    required this.description,
    required this.copies,
  });

  factory BookDetails.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final group = _asMap(data['group']);
    final description = BookDescription.fromJson(_asMap(data['description']));
    final copies = data['copies'];
    final availability = _stringValue(group['availability']);
    final totalCopies = _intValue(group['copies'], fallback: 0);

    return BookDetails(
      book: Book(
        id: _stringValue(description.id, fallback: _stringValue(group['id'])),
        title: _stringValue(group['title'], fallback: description.title),
        author: _stringValue(group['author'], fallback: description.author),
        coverImage: description.coverUrl,
        year: _intValue(group['publication_year'], fallback: 0),
        callNumber: description.callNumber,
        contentType: description.format,
        section: '',
        availability: availability.isEmpty ? 'Unavailable' : availability,
        isAvailable: availability.toLowerCase() == 'available',
        totalCopies: totalCopies,
        availableCopies: availability.toLowerCase() == 'available'
            ? totalCopies
            : 0,
      ),
      description: description,
      copies: copies is List
          ? copies
                .map((copy) => BookCopy.fromJson(_asMap(copy)))
                .toList(growable: false)
          : const [],
    );
  }
}

class BookDescription {
  final String id;
  final String title;
  final String author;
  final String format;
  final String edition;
  final String published;
  final String isbn;
  final String callNumber;
  final String? coverUrl;
  final String generalNote;
  final String physicalDescription;
  final String bibliography;
  final String subjectTopic;
  final String subjectForm;
  final String genre;
  final String series;

  const BookDescription({
    required this.id,
    required this.title,
    required this.author,
    required this.format,
    required this.edition,
    required this.published,
    required this.isbn,
    required this.callNumber,
    this.coverUrl,
    required this.generalNote,
    required this.physicalDescription,
    required this.bibliography,
    required this.subjectTopic,
    required this.subjectForm,
    required this.genre,
    required this.series,
  });

  factory BookDescription.fromJson(Map<String, dynamic> json) {
    return BookDescription(
      id: _stringValue(json['id']),
      title: _stringValue(json['title'], fallback: 'Untitled'),
      author: _stringValue(json['author'], fallback: 'Unknown author'),
      format: _stringValue(json['format'], fallback: 'Book'),
      edition: _stringValue(json['edition']),
      published: _stringValue(json['published']),
      isbn: _stringValue(json['isbn']),
      callNumber: _stringValue(json['call_number']),
      coverUrl: _nullableString(json['cover_url']),
      generalNote: _stringValue(json['general_note']),
      physicalDescription: _stringValue(json['physical_description']),
      bibliography: _stringValue(json['bibliography']),
      subjectTopic: _stringValue(json['subject_topic']),
      subjectForm: _stringValue(json['subject_form']),
      genre: _stringValue(json['genre']),
      series: _stringValue(json['series']),
    );
  }
}

class BookCopy {
  final String id;
  final String accessionNo;
  final String callNumber;
  final String volume;
  final String collection;
  final String shelvingLocation;
  final String circulationType;
  final String circulationStatus;
  final String availability;
  final bool isHeld;
  final bool canAddToCart;
  final String barcode;
  final String rfid;

  const BookCopy({
    required this.id,
    required this.accessionNo,
    required this.callNumber,
    required this.volume,
    required this.collection,
    required this.shelvingLocation,
    required this.circulationType,
    required this.circulationStatus,
    required this.availability,
    this.isHeld = false,
    this.canAddToCart = false,
    required this.barcode,
    required this.rfid,
  });

  bool get isAvailable => canAddToCart;

  factory BookCopy.fromJson(Map<String, dynamic> json) {
    final availability = _stringValue(json['availability']);
    final canAddToCart = json['can_add_to_cart'] == true ||
        availability.toLowerCase() == 'available';

    return BookCopy(
      id: _stringValue(json['id']),
      accessionNo: _stringValue(json['accession_no']),
      callNumber: _stringValue(json['call_number']),
      volume: _stringValue(json['volume']),
      collection: _stringValue(json['collection']),
      shelvingLocation: _stringValue(json['shelving_location']),
      circulationType: _stringValue(json['circulation_type']),
      circulationStatus: _stringValue(json['circulation_status']),
      availability: availability,
      isHeld: json['is_held'] == true ||
          availability.toLowerCase() == 'on hold',
      canAddToCart: canAddToCart,
      barcode: _stringValue(json['barcode']),
      rfid: _stringValue(json['rfid']),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

String _stringValue(Object? value, {String fallback = ''}) {
  final stringValue = value?.toString();
  return stringValue == null || stringValue.isEmpty ? fallback : stringValue;
}

String? _nullableString(Object? value) {
  final stringValue = value?.toString();
  return stringValue == null || stringValue.isEmpty ? null : stringValue;
}

int _intValue(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}
