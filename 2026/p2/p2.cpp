#include <iostream>

using namespace std;

char prompt1[] = "Please input array A:\n";
char prompt2[] = "Please input a key value:\n";
int arr[100];

int check_arr(int arr[], int size) {
  int status = 0; // 0: not sorted; 1: ascending; 2: descending; 3: monotonic
  if (size == 0) {
    return 0;
  } else if (size == 1) {
    return 1;
  }

  if (arr[0] < arr[1]) {
    status = 1;
  } else if (arr[0] > arr[1]) {
    status = 2;
  } else {
    status = 3;
  }

  for (int i = 1; i < size; i++) {
    if (arr[i - 1] > arr[i]) {
      if (status == 1) {
        return 0;
      } else if (status == 3) {
        status = 2;
      }
    } else if (arr[i - 1] < arr[i]) {
      if (status == 2) {
        return 0;
      } else if (status == 3) {
        status = 1;
      }
    }
  }
  return status;
}

void binary_search_ascending(int arr[], int l, int r, int key, int step) {
  cout << "Step " << step << ": ";
  if (l > r) {
    cout << "Not found!\n";
    return;
  }

  int m = l + (r - l) / 2;
  cout << "A[" << m << "] ";

  if (arr[m] < key) {
    cout << "< " << key << "\n";
    binary_search_ascending(arr, m + 1, r, key, step + 1);
  } else if (arr[m] > key) {
    cout << "> " << key << "\n";
    binary_search_ascending(arr, l, m - 1, key, step + 1);
  } else {
    cout << "= " << key << "\n";
  }
}

void binary_search_descending(int arr[], int l, int r, int key, int step) {
  cout << "Step " << step << ": ";
  if (l > r) {
    cout << "Not found!\n";
    return;
  }

  int m = l + (r - l) / 2;
  cout << "A[" << m << "] ";

  if (arr[m] < key) {
    cout << "< " << key << "\n";
    r = m - 1;
    step += 1;
    binary_search_descending(arr, l, r, key, step);
  } else if (arr[m] > key) {
    cout << "> " << key << "\n";
    l = m + 1;
    step += 1;
    binary_search_descending(arr, l, r, key, step);
  } else {
    cout << "= " << key << "\n";
  }
}

int main() {
  string input;
  cout << prompt1;
  cin >> input;
  int counter = 0;
  bool is_negative = false;
  string curr;
  for (char c : input) {
    if (c != ',') {
      if (c == '-') {
        is_negative = true;
      } else {
        curr += c;
      }
    } else {
      arr[counter] = stoi(curr);
      if (is_negative) {
        arr[counter] = -arr[counter];
      }
      is_negative = false;
      counter++;
      curr = "";
    }
  }
  arr[counter] = stoi(curr);
  if (is_negative) {
    arr[counter] = -arr[counter];
  }
  counter++;

  int status = check_arr(arr, counter);
  if (status == 0) {
    cout << "Error! The array is not sorted." << "\n";
    return 0;
  }

  int key;
  cout << prompt2;
  cin >> key;

  if (status == 1 || status == 3) {
    binary_search_ascending(arr, 0, counter - 1, key, 1);
  } else {
    binary_search_descending(arr, 0, counter - 1, key, 1);
  }

  return 0;
}
