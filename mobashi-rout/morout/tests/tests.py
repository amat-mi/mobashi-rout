from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
import base64


class GeocodeViewTestCase(APITestCase):
    def setUp(self):
        self.client = APIClient()

    def test_geocode_view_with_valid_query(self):
        query = "Hello, World!"
        query_encoded = base64.urlsafe_b64encode(
            query.encode()).decode().rstrip("=")
        response = self.client.get(
            reverse('geocode'), {'query': query_encoded})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['message'],
                         f"Geocode GET response for query: {query}")

    def test_geocode_view_with_invalid_query(self):
        query_encoded = "Invalid base64url string"
        response = self.client.get(
            reverse('geocode'), {'query': query_encoded})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.data['error'], "Invalid query parameter. It must be a base64url encoded string.")

    def test_geocode_view_with_empty_query(self):
        query = ""
        query_encoded = base64.urlsafe_b64encode(
            query.encode()).decode().rstrip("=")
        response = self.client.get(
            reverse('geocode'), {'query': query_encoded})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.data['error'], "Invalid query parameter. It must be a base64url encoded string.")


class ReverseViewTestCase(APITestCase):
    def setUp(self):
        self.client = APIClient()

    def test_reverse_view_with_valid_query(self):
        query = "Hello, World!"
        query_encoded = base64.urlsafe_b64encode(
            query.encode()).decode().rstrip("=")
        response = self.client.get(
            reverse('reverse'), {'query': query_encoded})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['message'],
                         f"Reverse GET response for query: {query}")

    def test_reverse_view_with_invalid_query(self):
        query_encoded = "Invalid base64url string"
        response = self.client.get(
            reverse('reverse'), {'query': query_encoded})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.data['error'], "Invalid query parameter. It must be a base64url encoded string.")
