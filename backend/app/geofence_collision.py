"""Geospatial bounding box and proximity perimeter collision detector."""


class GeofenceDetector:
    """Evaluates whether incident coordinates fall within critical alert perimeters."""

    @staticmethod
    def is_inside_bounding_box(lat: float, lon: float, min_lat: float, max_lat: float, min_lon: float, max_lon: float) -> bool:
        """Determines if a GPS point is within the geographic bounding perimeter."""
        return min_lat <= lat <= max_lat and min_lon <= lon <= max_lon
