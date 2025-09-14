/* Include files */

#include "mmwave_sim_cgxe.h"
#include "m_47zkef9zcr8EqBPKLggdWH.h"

unsigned int cgxe_mmwave_sim_method_dispatcher(SimStruct* S, int_T method, void*
  data)
{
  if (ssGetChecksum0(S) == 3011781538 &&
      ssGetChecksum1(S) == 3612083790 &&
      ssGetChecksum2(S) == 2628669709 &&
      ssGetChecksum3(S) == 988646539) {
    method_dispatcher_47zkef9zcr8EqBPKLggdWH(S, method, data);
    return 1;
  }

  return 0;
}
