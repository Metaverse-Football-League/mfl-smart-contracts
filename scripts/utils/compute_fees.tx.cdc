import FlowFees from "../../../contracts/_libs/FlowStorageFees.cdc"

pub fun main(
  inclusionEffort: UFix64,
  executionEffort: UFix64
): UFix64 {
  return FlowFees.computeFees(inclusionEffort: inclusionEffort, executionEffort: executionEffort)
}
