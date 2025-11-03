# Jitendex Dictionary

This project uses the Jitendex dictionary for Japanese-English translations.

## Automatic Download

**The app automatically downloads the dictionary (~112 MB) on first launch.**

The database is downloaded from:
https://github.com/T4toh/jitendex-parser/releases/download/v0.0.1/jitendex.db

No manual setup is required! Just open the Dictionary tab and the app will:

1. Check if the database exists locally
2. Download it automatically if not found
3. Display download progress
4. Start using it immediately after download

## For Developers

If you want to include the database in your development assets folder:

## For Developers

If you want to include the database in your development assets folder:

1. **Download the database manually:**
   Download from the [releases page](https://github.com/T4toh/jitendex-parser/releases/download/v0.0.1/jitendex.db)

2. **Place in assets:**
   Put `jitendex.db` in `assets/dicts/` directory

3. **Update pubspec.yaml:**
   The database is already configured in the assets (though it's gitignored)

The app will use the local copy as a fallback if the download fails.

## Database Schema

The database consists of two tables:

- `terms`: Contains dictionary terms

  - `id`: Primary key
  - `term`: Japanese term (e.g., '食べる')
  - `reading`: Reading in hiragana/katakana (e.g., 'たべる')
  - `popularity`: Popularity score (0-200, higher = more common)
  - `sequence`: Unique JMdict identifier

- `definitions`: Contains definitions for terms
  - `id`: Primary key
  - `term_id`: Foreign key to `terms.id`
  - `definition`: Definition in JSON format (parsed by the app)

## Credits

- Dictionary data: [Jitendex](https://jitendex.org/)
- Parser: [T4toh/jitendex-parser](https://github.com/T4toh/jitendex-parser)

## Example: Displaying Data in a Flutter App

Here is a more complete example of how to query the database and display the results in a Flutter widget.

First, define a `Term` model class to hold the data from the database:

```dart
class Term {
  final String term;
  final String reading;
  final String definition;

  Term({required this.term, required this.reading, required this.definition});

  @override
  String toString() {
    return 'Term{term: $term, reading: $reading, definition: $definition}';
  }
}
```

Next, create a function to search for a term and map the results to a list of `Term` objects:

```dart
Future<List<Term>> search(String searchTerm) async {
  final db = await getDatabase();
  final List<Map<String, dynamic>> maps = await db.rawQuery(
    '''
    SELECT t.term, t.reading, d.definition
    FROM terms t
    INNER JOIN definitions d ON t.id = d.term_id
    WHERE t.term = ?
    ''', [searchTerm]);

  return List.generate(maps.length, (i) {
    return Term(
      term: maps[i]['term'],
      reading: maps[i]['reading'],
      definition: maps[i]['definition'],
    );
  });
}
```

Finally, you can use this function in a `FutureBuilder` to display the data in a widget:

```dart
class SearchResults extends StatelessWidget {
  final String searchTerm;

  SearchResults({required this.searchTerm});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Term>>(
      future: search(searchTerm),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(snapshot.data![index].term),
                subtitle: Text(snapshot.data![index].reading),
                trailing: Text(snapshot.data![index].definition),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```
