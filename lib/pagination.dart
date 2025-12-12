import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('=== Pagination Example ===\n');
  
  final paginator = PaginatedList();
  await paginator.start();
}

class PaginatedList {
  final List<dynamic> _items = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _itemsPerPage = 10;

  Future<void> start() async {
    // Load initial page
    await _fetchData();
    _displayItems();

    // Interactive loop to load more pages
    while (_hasMore) {
      stdout.write('\nPress Enter to load more data (or type "q" to quit): ');
      final input = stdin.readLineSync()?.trim().toLowerCase();
      
      if (input == 'q' || input == 'quit') {
        break;
      }
      
      if (_hasMore && !_isLoading) {
        await _fetchData();
        _displayItems();
      } else if (!_hasMore) {
        print('\nNo more data available.');
        break;
      }
    }
    
    print('\n=== End of Pagination ===');
    print('Total items loaded: ${_items.length}');
  }

  Future<void> _fetchData() async {
    if (_isLoading) return;
    
    _isLoading = true;
    print('\nLoading page $_page...');

    try {
      // Example API with pagination (replace with your API)
      final response = await http.get(Uri.parse(
          'https://jsonplaceholder.typicode.com/posts?_page=$_page&_limit=$_itemsPerPage'));

      if (response.statusCode == 200) {
        final List<dynamic> newItems = json.decode(response.body);

        if (newItems.isEmpty) {
          _hasMore = false;
          print('No more data available.');
        } else {
          _page++;
          _items.addAll(newItems);
          print('Loaded ${newItems.length} items (Total: ${_items.length})');
        }
      } else {
        throw Exception('Failed to load data: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      _hasMore = false;
    } finally {
      _isLoading = false;
    }
  }

  String _repeatString(String char, int count) {
    return List.filled(count, char).join();
  }

  void _displayItems() {
    if (_items.isEmpty) {
      print('\nNo items to display.');
      return;
    }

    final separator = _repeatString('=', 80);
    final lineSeparator = _repeatString('-', 80);
    
    print('\n$separator');
    print('PAGE ${(_page - 1)} - Displaying ${_items.length} items');
    print('$separator\n');

    // Display items from the last loaded page
    final startIndex = _items.length > _itemsPerPage 
        ? _items.length - _itemsPerPage 
        : 0;
    
    for (int i = startIndex; i < _items.length; i++) {
      final item = _items[i];
      print(lineSeparator);
      print('ID: ${item['id']}');
      print('Title: ${item['title']}');
      
      final body = item['body']?.toString() ?? '';
      final bodyPreview = body.length > 100 ? '${body.substring(0, 100)}...' : body;
      print('Body: $bodyPreview');
      print('User ID: ${item['userId']}');
      print('');
    }
    
    print(separator);
    if (_hasMore) {
      print('More data available. Current page: ${_page - 1}');
    } else {
      print('All data loaded.');
    }
  }
}
