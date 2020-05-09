const float PI = 3.1415926535;
const float TAU = PI * 2.0;

float polygon(in vec2 uv, float radius, float sides) {
  uv = uv * 2.0 - 1.0;
  float angle = atan(uv.x, uv.y);
  float slice = TAU / sides;
  float dist = length(uv);
  return step(radius, cos(floor(0.5 + angle / slice) * slice - angle) * dist);
}