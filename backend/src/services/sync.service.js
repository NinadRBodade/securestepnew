exports.syncData = async (records) => {
  return {
    success: true,
    syncedCount: records?.length || 0
  };
};