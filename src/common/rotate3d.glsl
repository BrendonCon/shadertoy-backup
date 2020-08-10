mat3 rotateX(float theta) {
  float s = sin(theta);
  float c = cos(theta);
  
  return mat3(1.0, 0.0, 0.0,
              0.0, c, -s,
              0.0, s, c);
}

mat3 rotateY(float theta) {
  float s = sin(theta);
  float c = cos(theta);

  return mat3(c, 0.0, s,
              0.0, 1.0, 0.0,
              -s, 0.0, c);
}

mat3 rotateZ(float theta) {
  float s = sin(theta);
  float c = cos(theta);

  return mat3(c, -s, 0.0,
              s, c, 0.0,
              -0.0, 0.0, 1.0);	    
}