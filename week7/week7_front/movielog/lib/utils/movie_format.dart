// TMDB 값을 화면에 보여줄 형태로 바꾸는 함수 모음.

// '2024-05-01' → '2024'. 날짜가 없으면 null(연도를 표시하지 않는다).
String? releaseYear(String? releaseDate) {
  if (releaseDate == null || releaseDate.length < 4) return null;
  return releaseDate.substring(0, 4);
}

// TMDB 평점(0 ~ 10)을 MovieLog의 5점 만점으로 바꾼다.
double toFivePointRating(double voteAverage) => voteAverage / 2;
