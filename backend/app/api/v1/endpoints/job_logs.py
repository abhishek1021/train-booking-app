from fastapi import APIRouter, HTTPException, status, Depends
from typing import List, Dict, Any
from app.services.cronjob_service import CronjobService

router = APIRouter()

@router.get("/{job_id}", response_model=List[Dict[str, Any]])
async def get_job_logs(job_id: str):
    """Get all logs for a specific job"""
    try:
        logs = CronjobService.get_job_logs(job_id)
        return logs
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching logs for job {job_id}: {str(e)}"
        )
